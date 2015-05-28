# Building

A iOS Cordova application including the *cordova-plugin-iosrtc* plugin can be built using the [cordova-cli](https://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface) or Xcode.


## Build with cordova-cli

Once the plugin is installed build the application as usual:

```bash
$ cordova build ios
```

*NOTE:* If you need to install more iOS Cordova plugins coded in Swift within your project then check the "Bridging Header" section below.


## Build with Xcode

Xcode >= 6.3 is required due to Swift language.

When adding the `ios` platform to a Cordova project a Xcode project is automatically generated at `platforms/ios/PROJECT_NAME.xcodeproj/`. Open it with Xcode and follow these steps:

* Set "iOS Deployment Target" to `7.0` or higher within your project settings.
* Set "Deployment Target" to `7.0` or higher within the project target settings.
* Within the project "Build Settings" add an entry to the "Runpath Search Paths" setting with value `@executable_path/Frameworks`.
* Within the project "Build Settings" set "Objective-C Bridging Header" to `PROJECT_NAME/Plugins/com.eface2face.iosrtc/cordova-plugin-iosrtc-Bridging-Header.h` (read more about the "Bridging Header" below).


## Bridging Header

The plugin is coded in Swift language but it makes use of the Cordova Objective-C headers and the [Google's WebRTC Objective-C wrapper](https://chromium.googlesource.com/external/webrtc/+/master/talk/app/webrtc/objc/) so a [Bridging Header](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) is required.

When building the Cordova app with the `cordova-cli` the plugin automatically adds its [Bridging Header](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/src/cordova-plugin-iosrtc-Bridging-Header.h) to the project via a [hook](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/hooks/add_swift_support.js). When using Xcode the steps above must be manually performed.

It may happen that your Cordova application uses more than a single plugin coded in Swift, each of them requiring its own Bridging Header file. Unfortunately just a single Bridging Header can be set in a Xcode project. The solution is to create a "Unified-Bridging-Header.h" file within your project and include all the Bridging Header files required by the plugins in there. For example:

*Unified-Bridging-Header.h:*

```c
// cordova-plugin-apple-watch "Apple Watch"
#import "Watch-Bridge.h"

// com.eface2face.iosrtc "ordova-plugin-iosrtc"
#import "cordova-plugin-iosrtc-Bridging-Header.h"
```

And then set `Unified-Bridging-Header.h` as the value of the "Objective-C Bridging Header" build setting in your Xcode project.

For more information check this [issue](https://github.com/eface2face/cordova-plugin-iosrtc/issues/9).
