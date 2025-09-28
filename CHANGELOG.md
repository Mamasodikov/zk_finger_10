## 1.0.0 - Major Modernization Release 🚀

**BREAKING CHANGES:**
* **Flutter v3.35.3 Compatibility**: Updated plugin to work with Flutter v3.35.3 and latest Dart SDK
* **Android Plugin V2 Embedding**: Migrated from deprecated V1 embedding to modern V2 embedding
* **Modern Android Support**: Updated to support Android API 34+ with proper security compliance
* **Gradle Modernization**: Updated Android Gradle Plugin to 8.7.2 and Gradle to 8.10.2

**New Features:**
* **Bidirectional Data Management**: Added fingerprint template management capabilities
  - `getUserFeature(String userId)` - Retrieve fingerprint feature data for a specific user
  - `getAllUsers()` - Get all users and their fingerprint data from the database
  - `getUserCount()` - Get the total count of users in the database
  - `updateUserFeature(String userId, String feature)` - Update fingerprint feature data for an existing user
  - `checkUserExists(String userId)` - Check if a user exists in the database
* **Enhanced Database Operations**: Improved SQLite integration with proper error handling
* **Modern Architecture**: Implemented proper lifecycle management and resource cleanup

**Technical Improvements:**
* **Build System**: Updated to use new Flutter Gradle plugin approach
* **Dependencies**: Updated all dependencies to latest compatible versions
* **Security**: Fixed broadcast receiver registration for Android API 34+
* **Performance**: Optimized database operations and memory management
* **Error Handling**: Enhanced error reporting and exception handling

**Bug Fixes:**
* Fixed runtime crashes on Android API 34+
* Resolved Flutter embedding compatibility issues
* Fixed plugin registration and lifecycle management
* Corrected database transaction handling
* Fixed memory leaks in fingerprint processing

**Documentation:**
* Added comprehensive modernization guide
* Updated API documentation with new methods
* Included migration instructions for existing projects
* Added troubleshooting section for common issues

**Compatibility:**
* **Minimum Flutter**: 3.35.0+
* **Minimum Dart SDK**: 3.1.0+
* **Android**: API 21+ (Android 5.0+)
* **Target Android**: API 34 (Android 14)

## 0.0.6

* added "verify" (match 2 fingers: 1:1 comparison) and "clearAndLoad" methods (batch load to database)

## 0.0.5

* Hot fixes related to x86 architecture

## 0.0.4

* Support for x86_64 devices (x86 via ARM emulation)
* Bug fixes

## 0.0.3

* minor fixes*

## 0.0.2

* Some hotfixes*

## 0.0.1

* This is initial release of zkfinger10 package