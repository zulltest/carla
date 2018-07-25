@echo %FILE_N% off

setlocal

rem ============================================================================
rem -- Check for compiler ------------------------------------------------------
rem ============================================================================

where cl
if errorlevel 1 goto error_cl

rem TODO: check for x64 and not x86 or x64_x86

rem ============================================================================
rem -- Parse arguments ---------------------------------------------------------
rem ============================================================================

set LOCAL_PATH=%~dp0
set "FILE_N=-[%~n0]:"

set INSTALLERS_DIR=%LOCAL_PATH%..\InstallersWin\
set INSTALLATION_DIR=%LOCAL_PATH%..\..\Build\
set VERSION_FILE=%LOCAL_PATH%..\ContentVersions.txt
set CONTENT_DIR=%LOCAL_PATH%..\..\Unreal\CarlaUE4\Content

set TOOLSET=msvc-14.1
set NUMBER_OF_ASYNC_JOBS=%NUMBER_OF_PROCESSORS%

:arg-parse
if not "%1"=="" (
    if "%1"=="-j" (
        set NUMBER_OF_ASYNC_JOBS=%2
        shift
    )

    if "%1"=="--boost-toolset" (
        set TOOLSET=%2
        shift
    )

    if "%1"=="-h" (
        goto help
    )

    if "%1"=="--help" (
        goto help
    )

    shift
    goto :arg-parse
)

rem ============================================================================
rem -- Basic info and setup ----------------------------------------------------
rem ============================================================================

echo %FILE_N% Asynchronous jobs:  %NUMBER_OF_ASYNC_JOBS%
echo %FILE_N% Boost toolset:      %TOOLSET%
echo %FILE_N% Install directory:  %INSTALLATION_DIR%

if not exist "%CONTENT_DIR%" (
    echo %FILE_N% Creating %CONTENT_DIR% folder...
    mkdir %CONTENT_DIR%
)

if not exist "%INSTALLATION_DIR%" (
    echo %FILE_N% Creating %INSTALLATION_DIR% folder...
    mkdir %INSTALLATION_DIR%
)

rem ============================================================================
rem -- Download and install rpclib ---------------------------------------------
rem ============================================================================

echo %FILE_N% Installing rpclib...
call %INSTALLERS_DIR%install_rpclib.bat^
    --build-dir %INSTALLATION_DIR%^
    --delete-src

if not defined install_rpclib (
    echo.
    echo %FILE_N% Failed while installing rpclib.
    goto failed
)

rem ============================================================================
rem -- Download and install Google Test ----------------------------------------
rem ============================================================================

echo.
echo %FILE_N% Installing Google Test...
call %INSTALLERS_DIR%install_gtest.bat^
    --build-dir %INSTALLATION_DIR%^
    --delete-src

if not defined install_gtest (
    echo.
    echo %FILE_N% Failed while installing Google Test.
    goto failed
)

rem ============================================================================
rem -- Download and install Boost ----------------------------------------------
rem ============================================================================

echo.
echo %FILE_N% Installing Boost...
call %INSTALLERS_DIR%install_boost.bat^
    --build-dir %INSTALLATION_DIR%^
    --toolset %TOOLSET%^
    -j %NUMBER_OF_ASYNC_JOBS%^
    --delete-src

if not defined install_boost (
    echo.
    echo %FILE_N% Failed while installing Boost.
    goto failed
)

rem ============================================================================
rem -- Assets download URL -----------------------------------------------------
rem ============================================================================

FOR /F "tokens=2" %%i in (%VERSION_FILE%) do (
    set HASH=%%i
)
set URL=https://drive.google.com/open?id=%HASH%

FOR /F "tokens=1 delims=:" %%i in (%VERSION_FILE%) do (
    set ASSETS_VERSION=%%i
)

rem ============================================================================
rem -- Generate CMake ----------------------------------------------------------
rem ============================================================================



goto success

rem ============================================================================
rem -- Messages and Errors -----------------------------------------------------
rem ============================================================================

:success
    echo.
    echo %FILE_N%
    echo  ###########
    echo  # SUCCESS #
    echo  ###########
    echo.
    echo  IMPORTANT!
    echo.
    echo  All the CARLA library dependences should be installed now.
    echo  (You can remove all "*-src" folders in %INSTALLATION_DIR% directory)
    echo.
    echo  You only need the ASSET PACK with all the meshes and textures.
    echo.
    echo  This script provides the assets for CARLA %ASSETS_VERSION%
    echo  You can download the assets from here:
    echo.
    echo    %URL%
    echo.
    echo  If you want another version, search it in %VERSION_FILE%.
    echo.
    echo  Unzip it in the "%CONTENT_DIR%" folder.
    echo  After that, please run the "Rebuild.bat".

    goto eof

:help
    echo  Download and compiles all the necessary libraries to build CARLA.
    echo.
    echo  Commands:
    echo    -h, --help          -^> Shows this dialog.
    echo    -j ^<N^>              -^> N is the integer number of async jobs while compiling (default=1).
    echo    --boost-toolset [T] -^> Toolset corresponding to your compiler ^(default=^*^):
    echo                               Visual Studio 2013 -^> msvc-12.0
    echo                               Visual Studio 2015 -^> msvc-14.0
    echo                               Visual Studio 2017 -^> msvc-14.1 *

    goto eof

:error_cl
    echo.
    echo %FILE_N% [cl.exe ERROR] Can't find Visual Studio compiler.
    echo %FILE_N% [cl.exe ERROR] Possible causes:
    echo %FILE_N%                 - You are not using "Visual Studio x64 Native Tools Command Prompt".
    echo %FILE_N%                 - Make sure you use x64 (not x64_x86!)
    goto failed

:failed
    echo.
    echo %FILE_N%
    echo  Ok, and error ocurred, don't panic!
    echo  We have different platforms where you can find some help :)
    echo.
    echo  - Make sure you have read the documentation:
    echo    http://carla.readthedocs.io/en/latest/how_to_build_on_windows/
    echo.
    echo  - If the problem persists, you can ask on our Github's "Building on Windows" issue:
    echo    https://github.com/carla-simulator/carla/issues/21
    echo.
    echo  - Or just use our Discord channel!
    echo    We'll be glad to help you there :)
    echo    https://discord.gg/42KJdRj

    goto eof

:eof
    endlocal
