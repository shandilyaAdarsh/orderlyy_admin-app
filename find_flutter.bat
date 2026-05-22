@echo off
echo Searching for Flutter installation...
echo.

if exist "C:\flutter\bin\flutter.bat" (
    echo Found Flutter at: C:\flutter
    set FLUTTER_PATH=C:\flutter\bin
    goto :found
)

if exist "C:\src\flutter\bin\flutter.bat" (
    echo Found Flutter at: C:\src\flutter
    set FLUTTER_PATH=C:\src\flutter\bin
    goto :found
)

if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    echo Found Flutter at: %USERPROFILE%\flutter
    set FLUTTER_PATH=%USERPROFILE%\flutter\bin
    goto :found
)

if exist "%LOCALAPPDATA%\flutter\bin\flutter.bat" (
    echo Found Flutter at: %LOCALAPPDATA%\flutter
    set FLUTTER_PATH=%LOCALAPPDATA%\flutter\bin
    goto :found
)

if exist "%PROGRAMFILES%\flutter\bin\flutter.bat" (
    echo Found Flutter at: %PROGRAMFILES%\flutter
    set FLUTTER_PATH=%PROGRAMFILES%\flutter\bin
    goto :found
)

echo Flutter not found in common locations.
echo Please check Android Studio settings: File -^> Settings -^> Languages ^& Frameworks -^> Flutter
pause
exit /b 1

:found
echo.
echo Adding Flutter to PATH for this session...
set PATH=%FLUTTER_PATH%;%PATH%
echo.
echo Testing Flutter...
flutter --version
echo.
echo Flutter is now available! You can run:
echo   flutter devices
echo   flutter run
echo.
pause
