
# zkfinger10

Flutter package for ZKFingerPrint Live devices

## Getting Started

TODO:
- Migrate to Android Plugin V2 embedding (to catch app lifecycles)
- Fix SDK issues
- Add proper documentation

#### Add to Android Project:

- In the Manifest permission section add:

```xml
   <uses-permission
        android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"
        tools:ignore="ScopedStorage" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.hardware.usb.host" />
```
    
    
- Inside the activity tag in the Manifest file add:

```xml
<intent-filter>
    <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
    <action android:name="android.intent.action.BOOT_COMPLETED" />
  </intent-filter>
  <meta-data
           android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
           android:resource="@xml/device_filter" />
```
           
           
- In res folder add xml folder then add *device_filter.xml* with the following content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <usb-device vendor-id="6997" product-id="289" />
</resources>
```
==============

⚠️ Warning
Add these lines to your app-level build.gradle if you have problems on release:

```gradle
    buildTypes {
        release {
           ....
            
            //Add these lines when releasing your app
            minifyEnabled false
            shrinkResources false
            useProguard false 
            
        }
    }
```

Sample:

![com_example_zkfinger10_example](https://github.com/Mamasodikov/zk_finger_10/assets/64262986/91293ced-b40a-4ca3-9db3-465463815ccb)
