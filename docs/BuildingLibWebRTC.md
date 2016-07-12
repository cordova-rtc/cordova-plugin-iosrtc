# Build *libwebrtc* for cordova-plugin-iosrtc


### Get the *libwebrtc* source code

There are several ways to get and build the library. We choose a project that performs this task nicely:

* Clone the [webrtc-build-scripts](https://github.com/pristineio/webrtc-build-scripts) project and enter into it:
```bash
$ git clone https://github.com/pristineio/webrtc-build-scripts
$ cd webrtc-build-scripts
```

* Follow the project steps and fetch the *libwebrtc* source code:
```bash
$ source ios/build.sh
$ export WEBRTC_RELEASE=true
$ get_webrtc
```

* Set a specific *libwebrtc* version:
```bash
$ update2Revision 13311
```


### Apply `libwebrtc-objc-iosrtc.patch`

Google's *libwebrtc* Objective-C code lacks of `addtrack` and `removetrack` events in its `RTCMediaStream` class, making imposible to emulate them at JavaScript level. Thus a patch is needed to enable these W3C WebRTC features.

**eFace2Face** created such a patch and sent it to the Google's *WebRTC* project, but [it was rejected](https://webrtc-codereview.appspot.com/50109004/) by arguing that the future of the WebRTC API is "track based" rather than "stream based".

Since we live in the present we need those two events to properly implement the W3C WebRTC API in *cordova-plugin-iosrtc*, and hence the [patch](../extra/libwebrtc-objc-iosrtc.patch) is provided in the source code.

* Apply the patch provided at `extra/libwebrtc-objc-iosrtc.patch` into the Objective-C source code of *libwebrtc*:
```bash
$ cd ios/webrtc/src
$ patch -p1 < $PATH_TO_CORDOVA_PLUGIN_IOSRTC/extra/libwebrtc-objc-iosrtc.patch
```


### Apply `libwebrtc-objc-iosrtc-dtmf.patch`

Google's *libwebrtc* Objective-C wrapper does not implement a `RTCPeerConnection.createDTMF` function, which makes it impossible to send DTMF from the Objective-C wrapper, and in turn this plugin. Google [will not implement this](https://bugs.chromium.org/p/webrtc/issues/detail?id=4180)
because a new API was devised. Since we need to use this today, **AG Projects** created this patch exposing an API analogous to that on the C++ layer.

* Apply the patch provided at `extra/libwebrtc-objc-iosrtc-dtmf.patch` into the Objective-C source code of *libwebrtc*:
```bash
$ cd ios/webrtc/src
$ patch -p1 < $PATH_TO_CORDOVA_PLUGIN_IOSRTC/extra/libwebrtc-objc-iosrtc-dtmf.patch
```


### Misc

In order to enable H.264 support and compile libWebRTC properly, apply `libwebrtc-objc-iosrtc-misc.patch`.

```bash
$ cd ios/webrtc/src
$ patch -p1 < $PATH_TO_CORDOVA_PLUGIN_IOSRTC/extra/libwebrtc-objc-iosrtc-misc.patch


### Build *libwebrtc*

* Go back to the `webrtc-build-scripts` root folder and build *libwebrtc*:
```bash
$ build_webrtc
```

* Copy the *libwebrtc* Objective-C headers to *cordova-plugin-iosrtc*:
```bash
$ rm -f $PATH_TO_CORDOVA_PLUGIN_IOSRTC/src/webrtc-headers/*
$ cp ios/webrtc/src/talk/app/webrtc/objc/public/* $PATH_TO_CORDOVA_PLUGIN_IOSRTC/src/webrtc-headers/
```

* Copy the *libwebrtc* static library to *cordova-plugin-iosrtc*:
```bash
$ rm -f $PATH_TO_CORDOVA_PLUGIN_IOSRTC/lib/*
$ cp ios/webrtc/libWebRTC-LATEST-Universal-Release.a $PATH_TO_CORDOVA_PLUGIN_IOSRTC/lib/
```

