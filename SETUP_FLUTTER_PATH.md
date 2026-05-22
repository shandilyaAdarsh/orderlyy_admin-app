# Fix Flutter PATH - Step by Step Guide

## Method 1: Find Flutter SDK Path in Android Studio (EASIEST)

1. **Open Android Studio**
2. Go to: **File → Settings** (or press `Ctrl + Alt + S`)
3. Navigate to: **Languages & Frameworks → Flutter**
4. You'll see **Flutter SDK path** - copy this path
5. The path will look something like:
   - `C:\Users\ASUS\flutter`
   - `C:\src\flutter`
   - `C:\Users\ASUS\AppData\Local\Android\Sdk\flutter`

## Method 2: Add Flutter to PATH Permanently

Once you have the Flutter SDK path from Method 1:

### Option A: Using System Settings (Permanent)
1. Press `Win + X` and select **System**
2. Click **Advanced system settings**
3. Click **Environment Variables**
4. Under **User variables**, find **Path** and click **Edit**
5. Click **New**
6. Add: `YOUR_FLUTTER_PATH\bin` (e.g., `C:\flutter\bin`)
7. Click **OK** on all dialogs
8. **Restart your terminal/PowerShell**

### Option B: Using PowerShell Command (Permanent)
```powershell
# Replace C:\flutter with your actual Flutter path
$flutterPath = "C:\flutter\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$flutterPath", "User")
```

### Option C: For Current Session Only (Temporary)
```powershell
# Replace C:\flutter with your actual Flutter path
$env:Path += ";C:\flutter\bin"
flutter --version
```

## Method 3: Run from Android Studio Terminal

The easiest way without fixing PATH:

1. **Open Android Studio**
2. **Open your project**
3. Click **Terminal** tab at the bottom
4. Android Studio's terminal has Flutter in PATH automatically
5. Run your commands:
   ```bash
   flutter devices
   flutter run
   ```

## Method 4: Install Flutter Fresh (If Not Installed)

If Flutter is not installed at all:

1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to PATH (see Method 2)
4. Run: `flutter doctor`

## Quick Test

After fixing PATH, test with:
```bash
flutter --version
flutter doctor
```

## Run Your App on Android

```bash
# Check available devices
flutter devices

# Run on connected device/emulator
flutter run

# Or run specifically on Android
flutter run -d android
```

---

**RECOMMENDED:** Use Method 3 (Android Studio Terminal) - it's the quickest way to run your app!
