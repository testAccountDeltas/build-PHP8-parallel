Building parallel and PHP8
========
[![Windows](https://github.com/krakjoe/parallel/actions/workflows/windows.yml/badge.svg)](https://github.com/krakjoe/parallel/actions/workflows/windows.yml)

--------------------------------------------------------------------
To build [php](https://github.com/php/php-src) [parallel](https://github.com/krakjoe/parallel) on [windows 10](https://www.microsoft.com/ru-ru/software-download/windows10)+
You just need to download [build-PHP8-parallel.bat](https://github.com/testAccountDeltas/build-PHP8-parallel/blob/main/build-PHP8-parallel.bat) and run it in any place convenient for you

[Visual studio 2022](https://visualstudio.microsoft.com/ru/vs/community/) or [2019](https://learn.microsoft.com/ru-ru/visualstudio/releases/2019/redistribution#--download) build requirement

Supported versions for selection [PHP 8.0.30 8.1.28 8.2.5 8.2.20 8.3.8 8.3.9](https://windows.php.net/downloads/releases/archives/)

--------------------------------------------------------------------

Для сборки [php](https://github.com/php/php-src) [parallel](https://github.com/krakjoe/parallel) на [windows 10](https://www.microsoft.com/ru-ru/software-download/windows10)+
Вам достаточно загрузить [build-PHP8-parallel.bat](https://github.com/testAccountDeltas/build-PHP8-parallel/blob/main/build-PHP8-parallel.bat) и запустить в любом удобном для вас месте

Требование к сборке [Visual studio 2022](https://visualstudio.microsoft.com/ru/vs/community/) или [2019](https://learn.microsoft.com/ru-ru/visualstudio/releases/2019/redistribution#--download)

Поддерживамые версии для выбора [PHP 8.0.30 8.1.28 8.2.5 8.2.20 8.3.8 8.3.9](https://windows.php.net/downloads/releases/archives/)


--------------------------------------------------------------------

```
build-PHP8-parallel.bat
build-PHP8-parallel.bat --arch x64 --php 8.3.8 --debug 0 --shared 1 --force 0
build-PHP8-parallel.bat --arch x86 --php 8.2.5 --debug 1 --shared 1 --force 1
```

--------------------------------------------------------------------

Hello World
===========

```php
<?php
$runtime = new \parallel\Runtime();

$future = $runtime->run(function(){
    for ($i = 0; $i < 500; $i++)
        echo "*";

    return "easy";
});

for ($i = 0; $i < 500; $i++) {
    echo ".";
}

printf("\nUsing \\parallel\\Runtime is %s\n", $future->value());
```

This may output something like (output abbreviated):

```
.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
Using \parallel\Runtime is easy
```
