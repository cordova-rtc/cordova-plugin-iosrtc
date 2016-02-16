# Building


### Building Steps

An iOS Cordova application including the *cordova-plugin-iosrtc* plugin can be built using the [cordova-cli](https://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface) or Xcode.

The plugin provides a ["hook"](../extra/hooks/iosrtc-swift-support.js) to automate required modifications in both *cordova-cli* and Xcode generated projects.

* Put the hook script under the "hooks/" folder of your Cordova project (or wherever you prefer) and give it execution permission:
```bash
$ chmod +x hooks/iosrtc-swift-support.js
```
* Add these lines to you "config.xml" file:
```xml
<platform name="ios">
	<hook type="after_platform_add" src="hooks/iosrtc-swift-support.js" />
</platform>
```
* Make sure you have the NPM [xcode](https://www.npmjs.com/package/xcode) package installed (locally or globally):
```bash
$ npm install -g xcode
```
* Remove the iOS platform and add it again:
```bash
$ cordova platform remove ios
$ cordova platform add ios
```
* You have two options right now:
  * Open the Xcode project and compile your application.
  * Build the application as usual using the Cordova CLI:
```bash
$ cordova build ios
```


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

And then set `Unified-Bridging-Header.h` as the value of the "Objective-C Bridging Header" build setting in your Xcode project. For more information check this [issue](https://github.com/eface2face/cordova-plugin-iosrtc/issues/9).


#### Xcode

If you still prefer to do it manually open it with Xcode and follow these steps:

* Set "iOS Deployment Target" to `7.0` or higher within your project settings.
* Set "Deployment Target" to `7.0` or higher within the project target settings.
* Within the project "Build Settings" add an entry to the "Runpath Search Paths" setting with value `@executable_path/Frameworks`.
* Within the project "Build Settings" set "Objective-C Bridging Header" to `PROJECT_NAME/Plugins/cordova-plugin-iosrtc/cordova-plugin-iosrtc-Bridging-Header.h` (read more about the "Bridging Header" above).
* Within the project "Build Settings" set "Enable Bitcode" to "No".
