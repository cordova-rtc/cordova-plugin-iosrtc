# Building

### Building Steps

An iOS Cordova application including the *cordova-plugin-iosrtc* plugin can be built using the [cordova-cli](https://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface) or Xcode.

The plugin provides a ["hook"](../extra/hooks/iosrtc-swift-support.js) to automate required modifications in both *cordova-cli* and Xcode generated projects. It is no **longer necessary to add the "hook" manually or add and remove the platform again**, it is executed before and after cordova is preparing your application.

```
* You have two options right now:
  * Open the Xcode project and compile your application.
  * Build the application as usual using the Cordova CLI:
```bash
$ cordova build ios
```

For more details about Cordova hook life cycle see: [Hooks Guide - Apache Cordova](https://cordova.apache.org/docs/en/latest/guide/appdev/hooks/)


#### Bridging Header

The plugin is coded in Swift language but it makes use of the Cordova Objective-C headers and the [Google's WebRTC Objective-C wrapper](https://chromium.googlesource.com/external/webrtc/+/master/talk/app/webrtc/objc/) so a [Bridging Header](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) is required. When building (using the provided hook above) our [Bridging Header](../src/cordova-plugin-iosrtc-Bridging-Header.h) file is automatically added into your Cordova project.

It may happen that your Cordova application uses more than a single plugin coded in Swift, each of them requiring its own Bridging Header file. Unfortunately just a single Bridging Header can be set in a Xcode project. The solution is to create a "Unified-Bridging-Header.h" file within your project and include all the Bridging Header files required by the plugins in there. For example:

*Unified-Bridging-Header.h:*

```c
// cordova-plugin-apple-watch "Apple Watch"
#import "Watch-Bridge.h"

// cordova-plugin-iosrtc
#import "cordova-plugin-iosrtc-Bridging-Header.h"
```

And then set `Unified-Bridging-Header.h` as the value of the "Objective-C Bridging Header" build setting in your Xcode project. For more information check this [issue](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/9).


#### Minimum Xcode Version

You need to use minimum Xcode version 10.2 otherwise the build will fail due Apple Xcode know Bugs that have been fixed only on version above Xcode 10.2.

See: [Xcode 10.2 Release Notes](https://developer.apple.com/documentation/xcode_release_notes/xcode_10_2_release_notes)

#### Configuring Xcode manually

If you still prefer to do it manually open it with Xcode and follow these steps:

* Set "iOS Deployment Target" to `10.2` or higher within your project settings.
* Set "Deployment Target" to `10.2` or higher within the project target settings.
* Within the project "Build Settings" add an entry to the "Runpath Search Paths" setting with value `@executable_path/Frameworks`.
* Within the project "Build Settings" set "Objective-C Bridging Header" to `PROJECT_NAME/Plugins/cordova-plugin-iosrtc/cordova-plugin-iosrtc-Bridging-Header.h` (read more about the "Bridging Header" above).
* Within the project "Build Settings" set "Enable Bitcode" to "No".

#### iOS 10 notes

On iOS 10 each permission requested must be accompanied by a description or the app will crash. Here is an example:

```xml
<platform name="ios">
    <config-file parent="NSCameraUsageDescription" target="*-Info.plist">
	<string>Blink uses your camera to make video calls.</string>
    </config-file>
    <config-file parent="NSContactsUsageDescription" target="*-Info.plist">
	<string>Blink needs access to your contacts in order to be able to call them.</string>
    </config-file>
    <config-file parent="NSMicrophoneUsageDescription" target="*-Info.plist">
	<string>Blink uses your microphone to make calls.</string>
    </config-file>
</platform>
```

#### CocoaPods

Using CocoaPods will lose the bitcode setting on `pod install`. Adding post_install step to the Podfile can help

```
# Example post install to disable bitcode for pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Disable bitcode in order to support cordova-plugin-iosrtc
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

#### Capacitor

When adding ios support using `npx cap add ios` the bitcode setting mentioned above will need to be set to 'NO' for the App project. Also see above for CocoaPods concerns since `pod install` will run every time you do `npx cap sync ios`
