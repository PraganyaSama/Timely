@echo off
"C:\\Users\\sinpr\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\Flutter\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\groovy" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=23" ^
  "-DANDROID_PLATFORM=android-23" ^
  "-DANDROID_ABI=x86" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86" ^
  "-DANDROID_NDK=C:\\Users\\sinpr\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\sinpr\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\sinpr\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\sinpr\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=C:\\Users\\sinpr\\OneDrive\\Desktop\\Coding\\Flutter APP\\Attendance Manager\\attendance_manager\\android\\app\\build\\intermediates\\cxx\\RelWithDebInfo\\1g1h2j2p\\obj\\x86" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=C:\\Users\\sinpr\\OneDrive\\Desktop\\Coding\\Flutter APP\\Attendance Manager\\attendance_manager\\android\\app\\build\\intermediates\\cxx\\RelWithDebInfo\\1g1h2j2p\\obj\\x86" ^
  "-DCMAKE_BUILD_TYPE=RelWithDebInfo" ^
  "-BC:\\Users\\sinpr\\OneDrive\\Desktop\\Coding\\Flutter APP\\Attendance Manager\\attendance_manager\\android\\app\\.cxx\\RelWithDebInfo\\1g1h2j2p\\x86" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli
