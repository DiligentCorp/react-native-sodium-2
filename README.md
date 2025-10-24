# react-native-sodium

Precompiled binaries of [libsodium](https://libsodium.org) will be linked by default.
Optionally, you can choose to compile libsodium by yourself (run **npm&nbsp;run&nbsp;rebuild** in package directory). Source code will be downloaded and verified before compilation.

## 🚨 16KB Page Size Compatibility

**Important**: Starting November 1st, 2025, all apps targeting Android 15+ must support 16KB page sizes. This library has been updated to meet this requirement.

### Quick 16KB Build

```bash
npm run build:16kb
```

For detailed 16KB compatibility information, see [16KB_COMPATIBILITY.md](./16KB_COMPATIBILITY.md).

### Source compilation

###### General prerequisites

- gpg (macports, homebrew)
- minisign (homebrew)

###### MacOS prerequisites

- libtool (macports, homebrew)
- autoconf (macports, homebrew)
- automake (macports, homebrew)
- Xcode (12 or newer)

###### Android prerequisites

- Android NDK r28+ (for automatic 16KB support)
- CMake
- LLDB

### Build Commands

| Command                       | Description                                   |
| ----------------------------- | --------------------------------------------- |
| `npm run rebuild`             | Original build script (now with 16KB support) |
| `npm run build:16kb`          | Enhanced build with 16KB validation           |
| `npm run validate:16kb <apk>` | Validate 16KB compatibility of built APK      |

### Recompile and repackage

1. `yarn rebundle`

### Usage

1. `npm install react-native-sodium`
2. `npx pod-install ios`
3. Run your app.

### Example app

1. `yarn bootstrap`
2. `yarn example`
3. `yarn ios` or `yarn android`

### Credits

This repo is based on [react-native-sodium](https://github.com/lyubo/react-native-sodium) by @lyubo.
