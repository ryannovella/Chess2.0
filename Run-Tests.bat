@echo off
setlocal
echo ===================================================
echo Menjalankan Chess 2.0 Automated Test Suite...
echo ===================================================
set "PROJECT_PATH=%~dp0"
set "PROJECT_PATH=%PROJECT_PATH:~0,-1%"

"D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%PROJECT_PATH%" -s res://tests/test_runner.gd
set TEST_EXIT_CODE=%ERRORLEVEL%
echo.
if %TEST_EXIT_CODE% equ 0 (
    echo ===================================================
    echo [SUKSES] SEMUA TEST BERHASIL LULUS 100%!
    echo ===================================================
) else (
    echo ===================================================
    echo [ERROR] TERDAPAT TEST YANG GAGAL. CEK LOG DI ATAS!
    echo ===================================================
)
pause
exit /b %TEST_EXIT_CODE%
