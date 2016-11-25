#### Version 3.2.1

* Fix emitting "connected" stream event for local streams when using getUserMedia with promises.


#### Version 3.2.0

* Add support for RTCPeerConnection.getStats ([PR #163](https://github.com/eface2face/cordova-plugin-iosrtc/pull/163) by @oNaiPs)

* Set default deployment target to 9.0

* Document iOS 10 specific stuff

* Fix crash if RTCPeerConnection.close() is called twice

* Data channel improvements

* Updated documentation


#### Version 3.1.0

* Implement `RTCPeerConnection.createDTMFSender()` ([PR #189](https://github.com/eface2face/cordova-plugin-iosrtc/pull/189) by @saghul).

* Make `ios-websocket-hack.js` more reliable.


#### Version 3.0.1

* Fix positioning video elements using `z-index` and allow pure HTML on top of `<video>` elements ([PR #179](https://github.com/eface2face/cordova-plugin-iosrtc/issues/179) by @saghul and @1N50MN14).
 
* Improve `ios-websocket-hack.js` ([PR #138](https://github.com/eface2face/cordova-plugin-iosrtc/issues/138) by @apparition47).


#### Version 3.0.0

* Upgrade to `cordova-ios` 4 ([PR #159](https://github.com/eface2face/cordova-plugin-iosrtc/issues/159) by @apparition47).

* Swift: Use closure syntax for weak and unowned vars ([PR #160](https://github.com/eface2face/cordova-plugin-iosrtc/issues/160) by @oNaiPs).

* Swift: Sanitize arguments given to `NSLog()` ([issue #157](https://github.com/eface2face/cordova-plugin-iosrtc/issues/157)).

* `MediaDeviceInfo`: Add deprecated `facing` property ("front", "back" or "unknown") and update `kind` ("audio"/"video" become "audioinput"/"videoinput") ([issue #155](https://github.com/eface2face/cordova-plugin-iosrtc/issues/155)).

* Update `libwebrtc` to revision 12558 ([issue #169](https://github.com/eface2face/cordova-plugin-iosrtc/issues/169)).


#### Version 2.2.4

* Fix crash ([issue #144](https://github.com/eface2face/cordova-plugin-iosrtc/issues/144)).

* Update NPM dependencies.


#### Version 2.2.3

* Enable iOS native H.264 encoder/decoder.

* `RTCDataChannel`: Allow empty `label` ([issue #124](https://github.com/eface2face/cordova-plugin-iosrtc/issues/124)).

* Update [yaeti](https://www.npmjs.com/package/yaeti) dependency ([issue #123](https://github.com/eface2face/cordova-plugin-iosrtc/issues/123)).

* Fix retain on `pluginMediaStreamTrack` does not allow camera/mic to be freed ([PR #126](https://github.com/eface2face/cordova-plugin-iosrtc/pull/126)). Credits to @oNaiPs.

* Allow a handled video element to be removed from the DOM and added again later ([PR #127](https://github.com/eface2face/cordova-plugin-iosrtc/pull/127)). Credits to @oNaiPs.


#### Version 2.2.2

* Update `libwebrtc` to revision 11063 so `MediaStream` events (`onaddtrack` and `onremovetrack`) work again ([issue #95](https://github.com/eface2face/cordova-plugin-iosrtc/issues/95)).


#### Version 2.2.1

* `getUserMedia()`: Fire `errback` if given video constraints are not satisfied.


#### Version 2.2.0

* Move from `getMediaDevices()` to `enumerateDevices()`.
* Implement video constraints in `getUserMedia()`: `deviceId`, `width.min`, `width.max`, `height.min`, `height.max`, `frameRate`, `frameRate.min`, `frameRate.max`).
* Update deps and build on Node >= 4.


#### Version 2.1.0

* Update *libwebrtc* to latest revision (rev 10800).
* Enble iOS native H264 codec.


#### Version 2.0.2

* Enable CSS padding (thanks to @saghul) ([pull request #89](https://github.com/eface2face/cordova-plugin-iosrtc/issues/89)).


#### Version 2.0.1

* Don't crash if user or iOS settings deny access lo local audio/video devices ([issue #73](https://github.com/eface2face/cordova-plugin-iosrtc/issues/73)).


#### Version 2.0.0

* Swift 2.0 is here! Credits to @saghul for his [pull request](https://github.com/eface2face/cordova-plugin-iosrtc/pull/70).
* `extra/hooks/iosrtc-swift-support.js`: Set `BUILD_VERSION` to 7.0.


#### Version 1.4.5

* Add `cordova.plugins.iosrtc.observeVideo(video)` API for the plugin to handle `<video>` elements not yet in the DOM ([issue #49](https://github.com/eface2face/cordova-plugin-iosrtc/issues/49)).


#### Version 1.4.4

* Support CSS `border-radius` property in HTML video elements.


#### Version 1.4.3

* Make private properties more private ([issue #34](https://github.com/eface2face/cordova-plugin-iosrtc/issues/34)).


#### Version 1.4.2

* Use [yaeti](https://github.com/ibc/yaeti) module as `EventTarget` shim.


#### Version 1.4.1

* Release `MediaStreamRenderer` and revert `<video>` properties when the attached `MediaStream` emits "inactive" ([issue #27](https://github.com/eface2face/cordova-plugin-iosrtc/issues/27)).


#### Version 1.4.0

* Implemented some `<video>` properties such as `readyState`, `videoWidth` and `videoHeight` ([issue #25](https://github.com/eface2face/cordova-plugin-iosrtc/issues/25)).
* Building simplified for both Cordova CLI and Xcode by providing a single ["hook"](extra/hooks/iosrtc-swift-support.js) the user must add into his Cordova application (check the [Building](docs/Building.md) documentation for further details).


#### Version 1.3.3

* CSS `object-fit: none` properly implemented (don't clip the video).


#### Version 1.3.2

* CSS [object-fit](https://css-tricks.com/almanac/properties/o/object-fit/) property implemented in `<video>` elements ([issue #23](https://github.com/eface2face/cordova-plugin-iosrtc/issues/23)).


#### Version 1.3.1

* Stop "error" event propagation in `<video>` element when attaching a `MediaStream` to it ([issue #22](https://github.com/eface2face/cordova-plugin-iosrtc/issues/22)).


#### Version 1.3.0

* Plugin moved to [NPM](https://www.npmjs.com/package/cordova-plugin-iosrtc) registry and plugin ID renamed to *cordova-plugin-iosrtc*.


#### Version 1.2.8

* `iosrtc.registerGlobals()` also generates `window.webkitRTCPeerConnection` and `navigator.webkitGetUserMedia()` for backwards compatibility with WebRTC JavaScript wrappers/adapters that assume browser vendor prefixes (`webkit`, `moz`) in the underlying WebRTC API.



