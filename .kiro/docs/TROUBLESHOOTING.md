# Troubleshooting Guide

## Issue: Analyzer Shows "Missing concrete implementations" Errors

### Symptoms
```
error - Missing concrete implementations of '_$Order.toJson', 'getter _$Order.id', etc.
```

### Root Cause
The Freezed generated files exist but the analyzer cache hasn't picked them up, or the files are malformed.

### Solutions

#### Solution 1: Restart IDE (Quickest)
1. Close VS Code / Android Studio
2. Reopen the project
3. Wait for analyzer to reindex

#### Solution 2: Clean and Rebuild
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### Solution 3: Format Generated Files
```bash
dart format .
```

#### Solution 4: Restart Dart Analysis Server (VS Code)
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Dart: Restart Analysis Server"
3. Press Enter

#### Solution 5: Delete Generated Files and Regenerate
```bash
# Delete generated files
Remove-Item -Path "lib\**\*.freezed.dart" -Recurse -Force
Remove-Item -Path "lib\**\*.g.dart" -Recurse -Force

# Regenerate
dart run build_runner build --delete-conflicting-outputs
```

### Verification
After applying a solution, verify with:
```bash
flutter analyze
```

If you still see errors but the app runs successfully with `flutter run -d chrome`, the errors are false positives and can be ignored.

## Issue: App Won't Compile

### Check 1: Verify Generated Files Exist
```bash
Get-ChildItem -Path "lib\features\orders\domain\models\" -Filter "*.freezed.dart"
```

Should show:
- `money.freezed.dart`
- `order.freezed.dart`
- `order_item.freezed.dart`

### Check 2: Verify Imports
Ensure all files importing domain models have:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filename.freezed.dart';
part 'filename.g.dart';
```

### Check 3: Run Build Runner
```bash
dart run build_runner build --delete-conflicting-outputs --verbose
```

Look for errors in the output.

## Issue: Repository Not Found

### Symptom
```
error - Undefined class 'IOrdersRepository'
```

### Solution
Check import in `orders_notifier.dart`:
```dart
import '../../data/repositories/orders_repository_interface.dart';
```

## Issue: OrderStatus Type Conflicts

### Symptom
```
error - The argument type 'OrderStatus' can't be assigned to the parameter type 'OrderStatus'
```

### Solution
Use prefixed imports:
```dart
import '../../../../core/data/dtos/order_dto.dart' as dto;

// Then use:
dto.OrderStatus.fromString(status.name)
```

## Issue: Provider Not Found

### Symptom
```
error - Undefined name 'ordersRepositoryProvider'
```

### Solution
Check import in `orders_providers.dart`:
```dart
import '../../data/providers/orders_repository_providers.dart';
```

## Issue: App Runs But Shows No Data

### Check 1: Verify Repository Mode
In `orders_repository_providers.dart`:
```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.mock;  // Should be 'mock' for development
});
```

### Check 2: Check Console for Errors
Look for:
- Repository initialization errors
- Data source errors
- State hydration errors

### Check 3: Verify Mock Data
The mock data source should have sample orders. Check `orders_mock_datasource.dart`.

## Issue: State Not Persisting

### Check 1: LocalStorage Initialized
In `main.dart`:
```dart
await LocalStorage.initialize();
```

### Check 2: State Persistence Provider
Verify `statePersistenceProvider` is available in `orders_providers.dart`.

## Issue: Build Runner Fails

### Common Causes

#### Missing Dependencies
```bash
flutter pub get
```

#### Conflicting Outputs
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### Outdated Packages
```bash
flutter pub upgrade
```

## Quick Diagnostic Commands

### Check Flutter Version
```bash
flutter --version
```

### Check Dependencies
```bash
flutter pub deps
```

### Check for Conflicts
```bash
flutter pub deps --style=compact
```

### Analyze Code
```bash
flutter analyze --no-fatal-infos
```

### Run Tests
```bash
flutter test
```

## Getting Help

If issues persist:

1. Check the integration status:
   - Read `.kiro/docs/architecture/INTEGRATION_STATUS.md`

2. Review the architecture docs:
   - `.kiro/docs/architecture/SWAPPABLE_REPOSITORY_ARCHITECTURE.md`
   - `.kiro/docs/architecture/REPOSITORY_IMPLEMENTATION_SUMMARY.md`

3. Check recent changes:
   - Review git history
   - Check for uncommitted changes

4. Create a minimal reproduction:
   - Isolate the issue
   - Test with a simple example

## Common Warnings (Can Be Ignored)

### Info: Don't invoke 'print' in production code
- These are in test files and development code
- Can be ignored for now
- Replace with proper logging later

### Warning: Unused import
- Clean up unused imports when convenient
- Doesn't affect functionality

### Warning: Unused field
- In placeholder implementations (like `OrdersRestDataSource`)
- Will be used when implementing the actual REST client

## Emergency Reset

If everything is broken and you need to start fresh:

```bash
# 1. Clean everything
flutter clean
Remove-Item -Path ".dart_tool" -Recurse -Force
Remove-Item -Path "build" -Recurse -Force

# 2. Reinstall dependencies
flutter pub get

# 3. Regenerate code
dart run build_runner build --delete-conflicting-outputs

# 4. Restart IDE
# Close and reopen VS Code / Android Studio

# 5. Try running
flutter run -d chrome
```

---

**Last Updated**: Context Transfer Session
**Maintainer**: Development Team
