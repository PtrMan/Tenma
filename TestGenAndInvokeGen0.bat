@echo off

haxe dyna --main TestCodegen --interp
if %errorlevel% neq 0 exit /b %errorlevel%

haxe dyna --main TestInvokeOut0 --interp
if %errorlevel% neq 0 exit /b %errorlevel%
