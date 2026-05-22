# Add Flutter to PATH
# Usage: Edit the $flutterPath variable below with your Flutter SDK path, then run this script

Write-Host "=== Flutter PATH Setup ===" -ForegroundColor Cyan
Write-Host ""

# EDIT THIS LINE - Replace with your actual Flutter SDK path from Android Studio
$flutterPath = "C:\flutter\bin"  # Change this to your Flutter path!

Write-Host "Checking if Flutter exists at: $flutterPath" -ForegroundColor Yellow

if (Test-Path "$flutterPath\flutter.bat") {
    Write-Host "✓ Flutter found!" -ForegroundColor Green
    Write-Host ""
    
    # Add to current session
    $env:Path += ";$flutterPath"
    Write-Host "✓ Added to current session PATH" -ForegroundColor Green
    
    # Add permanently to user PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$flutterPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterPath", "User")
        Write-Host "✓ Added to permanent user PATH" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠ Please restart your terminal for permanent changes to take effect" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Already in permanent PATH" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Testing Flutter..." -ForegroundColor Cyan
    flutter --version
    
    Write-Host ""
    Write-Host "=== Setup Complete! ===" -ForegroundColor Green
    Write-Host "You can now run:" -ForegroundColor White
    Write-Host "  flutter devices" -ForegroundColor Gray
    Write-Host "  flutter run" -ForegroundColor Gray
    
} else {
    Write-Host "✗ Flutter not found at: $flutterPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Open Android Studio" -ForegroundColor White
    Write-Host "2. Go to: File → Settings → Languages & Frameworks → Flutter" -ForegroundColor White
    Write-Host "3. Copy the Flutter SDK path" -ForegroundColor White
    Write-Host "4. Edit this script and replace the flutterPath variable" -ForegroundColor White
    Write-Host "5. Run this script again" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"
