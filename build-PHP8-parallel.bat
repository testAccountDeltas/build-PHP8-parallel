@echo off

title build php

set DEPS=
set SNAP=
set OPTIONS=

setlocal enabledelayedexpansion

echo Select PHP version or enter manually:
set i=1
for %%v in (8.0.30 8.1.28 8.2.5 8.2.20 8.3.8) do (
    echo !i!. %%v
    set "version[!i!]=%%v"
    set /a i+=1
)
echo !i!. Enter your option

set /p getPHPVersion=Enter the version number (1-!i!) or the version itself:

if "%getPHPVersion%"=="" (
    echo Unknown PHP version
    goto :end
)

set "PHP_VER="
if %getPHPVersion% geq 1 if %getPHPVersion% leq !i! (
    for /L %%j in (1,1,%i%) do (
        if !getPHPVersion! == %%j (
            set "PHP_VER=!version[%%j]!"
        )
    )
)

if not defined PHP_VER (
    set "PHP_VER=%getPHPVersion%"
)


for /f "tokens=1-2 delims=." %%a in ("%PHP_VER%") do (
    set PHP_MAJOR=%%a
    set PHP_MINOR=%%b
)
if %PHP_MAJOR%==7 (
    if %PHP_MINOR% lss 2 (
        set CRT=vs14
    ) else if %PHP_MINOR%==2 (
        set CRT=vs15
    ) else (
        set CRT=vs15
    )
) else if %PHP_MAJOR%==8 (
    if %PHP_MINOR% lss 1 (
        set CRT=vs16
    ) else if %PHP_MINOR%==1 (
        set CRT=vs16
    ) else if %PHP_MINOR%==2 (
        set CRT=vs16
    ) else if %PHP_MINOR% geq 3 (
        set CRT=vs17
    )
) else (
    echo Unknown PHP version: %PHP_VER%
    goto :end
)

echo BUILD PHP x86 assembly? (Y/N)
set /p is32Bit=

if /I "%is32Bit%"=="Y" (
    set "ARCH=x86"
    set "vcvars=vcvars32.bat"
) else (
    set "ARCH=x64"
    set "vcvars=vcvars64.bat"
)


set isDebugInfo=Release
echo Build a debug version?? (Y/N)
set /p ANSWER=
if /I "%ANSWER%"=="Y" (
    set OPTIONS=%OPTIONS% --enable-debug
	set isDebugInfo=Debug
)

set isSharedInfo=no-shared
set SHARE=
echo Collect extensions as SHARE? (Y/N)
set /p ANSWER=
if /I "%ANSWER%"=="Y" (
    set SHARE==shared
	set isSharedInfo=Shared
)

set "titleSetBuild=Selected version php %PHP_VER% (%ARCH%, %CRT%, %isDebugInfo%, %isSharedInfo%)"
echo %titleSetBuild%
title %titleSetBuild%



set "VSWHERE_PATH="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    set "VSWHERE_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe" (
    set "VSWHERE_PATH=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
) else (
    echo vswhere.exe not found. Please install Visual Studio or download vswhere from https://github.com/microsoft/vswhere/releases
    goto :end
)
for /f "tokens=*" %%i in ('"%VSWHERE_PATH%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath') do (
    set "VS_INSTALL_PATH=%%i"
)

set "VCVARS_PATH=\VC\Auxiliary\Build\%vcvars%"
if defined VS_INSTALL_PATH (
    if exist "%VS_INSTALL_PATH%%VCVARS_PATH%" (
        call "%VS_INSTALL_PATH%%VCVARS_PATH%"
        if not errorlevel 0 (
            echo Failed to call %vcvars%
            goto :end
        )
        GOTO StartBuild
    ) else (
        echo "%vcvars% not found in %VS_INSTALL_PATH%%VCVARS_PATH%."
        goto :end
    )
) else (
    echo Visual Studio not found.
    goto :end
)

:StartBuild

if NOT EXIST php-sdk (
  curl -L https://codeload.github.com/php/php-sdk-binary-tools/tar.gz/refs/heads/master | tar xzf - && ren php-sdk-binary-tools-master php-sdk
)
if NOT EXIST parallel (
  curl -L https://codeload.github.com/krakjoe/parallel/tar.gz/refs/heads/develop | tar xzf - && ren parallel-develop parallel
)
set "parallelPath=%~dp0\parallel"
set "PHP_SDK_RUN_FROM_ROOT=%~dp0\php-sdk"
for %%i in (%PHP_SDK_RUN_FROM_ROOT%) do set PHP_SDK_RUN_FROM_ROOT=%%~fi
set "PHP_phpdev=%PHP_SDK_RUN_FROM_ROOT%\phpdev"
set "pathPHP=%PHP_phpdev%\%CRT%\%ARCH%"

if NOT EXIST "%pathPHP%" ( mkdir "%pathPHP%" )
if NOT EXIST "%pathPHP%\pecl" ( mkdir "%pathPHP%\pecl" )
if NOT EXIST "%pathPHP%\pecl\parallel" ( mklink /j "%pathPHP%\pecl\parallel" "%parallelPath%" )

set "downloadDir=%pathPHP%\php-%PHP_VER%"
if NOT EXIST "%downloadDir%" ( mkdir "%downloadDir%" )

set "phpArhive=%downloadDir%\php-%PHP_VER%.tar.gz"
if not exist "%phpArhive%" (
  curl -L https://github.com/php/php-src/archive/refs/tags/php-%PHP_VER%.tar.gz -o "%phpArhive%"
)
if NOT EXIST "%downloadDir%\buildconf.bat" ( tar xzf "%phpArhive%" -C "%downloadDir%" --strip-components 1 )

cd %PHP_SDK_RUN_FROM_ROOT%

call bin\phpsdk_setshell.bat %CRT% %ARCH%
call bin\phpsdk_setvars.bat
call bin\phpsdk_dumpenv.bat
call bin\phpsdk_buildtree.bat phpdev

cd php-%PHP_VER%

call ..\..\..\..\bin\phpsdk_deps -u --no-backup

set "zipFile=%pathPHP%\pthreads%ARCH%.zip"
if NOT EXIST "%pathPHP%\deps\bin\pthreadVC3.dll" (
	if NOT EXIST "%zipFile%" (
		curl -L https://windows.php.net/downloads/pecl/deps/pthreads-3.0.0-vs16-%ARCH%.zip -o "%zipFile%"
	)
	powershell -command "try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%zipFile%', '%pathPHP%\deps') } catch { }" >nul 2>&1
)

set buildNew=1
if EXIST config.nice.bat (
	echo "Do you want to build force??? (Y/N)"
	set /p Isforce=
	if /I "%Isforce%"=="N" (
		set buildNew=0
		call config.nice.bat
		nmake %SNAP%
		cd ..\..\..\..\..
	)
)

if %buildNew%==1 (
	call buildconf --force --add-modules-dir=..\pecl\ 
    call configure --enable-zts --enable-cli --with-curl%SHARE% --with-ffi%SHARE% --with-iconv --enable-phar%SHARE% --enable-filter%SHARE% --with-openssl%SHARE% --enable-sockets%SHARE% --enable-mbstring%SHARE% --with-libxml%SHARE% --enable-fileinfo%SHARE% --enable-xmlwriter%SHARE% --enable-tokenizer%SHARE% --enable-embed --with-parallel%SHARE% %OPTIONS%
    nmake %SNAP%
	
    cd ..\..\..\..\..
)



set dirPathExe=%downloadDir%\%ARCH%\%isDebugInfo%_TS
if EXIST "%dirPathExe%\tmp-php.ini" (
	ren "%dirPathExe%\tmp-php.ini" php.ini
)

set dirPathExe=%downloadDir%\%ARCH%\%isDebugInfo%_TS
if EXIST %dirPathExe% (
	copy /Y %pathPHP%\deps\bin\%DEPS%*.dll %dirPathExe%

	(
		echo @echo off
		echo cd %dirPathExe%
		echo IF EXIST php.exe ^(
		echo    php -m
		echo    php -v
		echo    php %downloadDir%\run-tests.php --offline --show-diff --set-timeout 240 "%parallelPath%\tests"
		echo    pause
		echo ^)
	) > windows_run_test_%PHP_VER%_%isDebugInfo%.bat
)

echo Assembly is complete.
:end
pause