# Building


### Building Steps

An iOS Cordova application including the *cordova-plugin-iosrtc* plugin can be built using the [cordova-cli](https://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface) or Xcode.

* You have two options right now:
  * Open the Xcode project and compile your application.
  * Build the application as usual using the Cordova CLI:
```bash
$ cordova build ios
```

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
