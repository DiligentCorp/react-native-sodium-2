# 16KB Page Size Compatibility

Starting November 1st, 2025, all apps targeting Android 15+ must support 16KB page sizes. This library has been updated to meet this requirement.

## What Changed

- Updated Android Gradle Plugin to 8.5.1+ for proper 16KB alignment
- Updated NDK to version 28+ which defaults to 16KB alignment
- Added CMake flags for 16KB page size support
- Rebuilt libsodium with 16KB alignment

## Building for 16KB Compatibility

1. **Update NDK**: Ensure you're using Android NDK r28 or higher
2. **Update AGP**: Use Android Gradle Plugin 8.5.1 or higher
3. **Rebuild Native Libraries**: Run the provided script to rebuild libsodium:
   ```bash
   ./build_16kb_libsodium.sh
   ```

## Validation

After building your app, validate 16KB compatibility:

```bash
./validate_16kb.sh path/to/your/app.apk
```

## Testing

Test your app on a 16KB emulator:

1. Download Android 15 with 16KB page size system images from SDK Manager
2. Create an emulator with the 16KB system image
3. Verify page size: `adb shell getconf PAGE_SIZE` (should return 16384)
4. Test your app thoroughly

## Troubleshooting

If you encounter issues:

1. Ensure all prebuilt libraries are rebuilt with 16KB alignment
2. Check that no code hardcodes PAGE_SIZE or assumes 4KB pages
3. Use `getpagesize()` or `sysconf(_SC_PAGESIZE)` instead of hardcoded values
4. Verify APK alignment with the validation script

For more information, see the [official Android documentation](https://developer.android.com/guide/practices/page-sizes).