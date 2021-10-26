# Build *libwebrtc* for cordova-plugin-iosrtc

### Get the *libwebrtc* source code

There are several ways to get and build the library. We choose a project that performs this task nicely:

[react-native-webrtc/blob/master/Documentation/BuildingWebRTC.md](https://github.com/react-native-webrtc/react-native-webrtc/blob/master/Documentation/BuildingWebRTC.md#building-webrtc)

Once you have WebRTC.framework copy the build into [lib](https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/lib/)

#### Generate xcframework

Once you have WebRTC.framework into [lib](https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/lib/), you need to generate WebRTC.xcframework

The script is here: https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/extra/ios_arch.js

1. go to `plugins/cordova-plugin-iosrtc/extra` folder
2. generate xcframework using: `node ios_arch.js --xcframework`
