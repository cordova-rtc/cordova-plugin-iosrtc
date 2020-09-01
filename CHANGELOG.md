#### Version 6.0.13
* Bump lodash from 4.17.15 to 4.17.19 #543
* Bump elliptic from 6.5.0 to 6.5.3 #553
* Add build doc for CocoaPods and Capacitor users #538
* Add SWIFT_VERSION and IPHONEOS_DEPLOYMENT_TARGET and DISABLE_IOSRTC_HOOK env options for extra/hooks/iosrtc-swift-support.js #512
* Improve PluginEnumerateDevices.getAllVideoDevices with builtInTrueDepthCamera and better ios 10.0 support #548
* Improve cleanup RTCPeerConnections, StreamRenderers, MediaStream, MediaStreamTracks when onReset and onAppTerminate is trigger
* Implement MediaDevices SHAM
* Fix crash in PluginEnumerateDevices when audioSession.availableInputs is empty
* Fix MediaDevices.prototype Object.create(EventTarget.prototype)
* Fix onaddtrack wihout stream crash during call initializing #532
* Fix Video Element Redundancy on Refresh / Re-Navigation on same page #535
* Fix Bridging header is getting added into the Widget/Extension as well causing build process to fail #504 via #513
* Fix iceRestart constraint doesnt work #530 ([PR #531](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/531) by @andrewvmail) 
* Add Plugin option MANUAL_INIT_AUDIO_DEVICE default to false  ([PR #503](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/503) by @andrewvmail) 
* Fix getUserMedia compatiblity with Twilio Video #497
* Fix attach stream to ontrack events only when available.
* Fix issue with pluginMediaStream creation causing black screen due duplicate rtcMediaStream.streamId

#### Version 6.0.12
* Implement RTCPeerConnection track event on PluginRTCPeerConnection and RTCPeerConnection SHIM #508
* Fix WebRTC-adapter <= 7.5.0 track SHIM failure
* Fix WebRTC-adapter >= 7.6.0 track missing SHIM
* Add SHAM for MediaStreamTrack.getSettings|getCapabilities
* Add Throw Error Not implemented for MediaStreamTrack.getConstraints|applyConstraints
* Fix RTCPeerConnection.prototype.getStats.length to match features detection #511
* Fix Error: Callbacks are not supported by "RTCPeerConnection.prototype.getStats" anymore, use Promise instead. #510 
* Fix Regex in iosrtc-swift-support.js returns wrong value #502
* Fix Backgroundcolor is now "clear" instead of "black" #514
* Fix gulp-util is deprecated - replace it #428
* Add support for MediaStreamTrack.clone() method #474
* Add basic RTCRtpTransceiver|RTCRtpSender|RTCRtpReceiver shim #423
* Fix getReceivers method doesn't return RTCRtpReceiver array #442
* Fix Blob only support for iOS 10.x that does not know MediaStream #495
* Incompatibility with Janus WebRTC gateway when using WebRTC-adapter >= 7.6.0 #505
* Improve getUserMedia compatiblity with Twilio Video #497

#### Version 6.0.11
* Fix possible duplicate remote streamId/trackId with janus/kurento/freeswitch or short duplicate name #493
* Fix Calling removeTrack/addTrack does not update renderer #492

#### Version 6.0.10
* Fix ios 10.2+ issue with loading cordova when iosrtc plugin present. #488
* Fix TypeError: undefined is not an object(evaluating 'originaMediaStream.prototype') #485
* Handle ios 10.x.x that does not have MediaStream Native Prototype and fallback on Blob with EventTarget shim #489

#### Version 6.0.9
* fix possible TypeError: null is not an object (evaluating 'iceCandidateFields.foundation') due fail match candidateToJson #473
* fix getStats typo report.timestamp #472
* Fix getMediaDevice audioConstraints to allowing audio devices change #470

#### Version 6.0.8
* Add Known Issues > iOS >= 13.3.1 Device support to README.md
* Implement candidateToJson SDP candidate parser into RTCIceCandidate to populate foundation, component, priority, type, address, ip, protocol, port, relatedAddress and relatedPort RTCIceCandidate values #468
* Fix PeerConnection.addStream|addTrack by using UUID().uuidString preffix for PluginMediaStream and PluginMediaStreamTrack only for Janus #467

#### Version 6.0.7
* Missing Event.target value on iosRTC Events to fix Datachannel for Janus.js #447
* Update extras/renderer-and-libwebrtc-tests.js

#### Version 6.0.6
* Update ios_arch.js script link ([PR #457](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/457) by @onerinas)
* Fix removeStream and add real Ids with UUID suffix to PluginMediaStream and PluginMediaStreamTrack ([PR #460](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/460)) 
* handle webrtc-adapter multiple video.optional constraints values add support for maxHeight and maxWidth
* Update README with sdpSemantics, bundlePolicy, rtcpMuxPolicy sample

#### Version 6.0.5
* Fix missing typeof on constraints.video.facingMode.ideal

#### Version 6.0.4
* Improve video constraints (width|height|aspectRatio|frameRate).(ideal|exact) and add (aspectRatio|frameRate|facingMode).(ideal|exact) support enhancement #451
* Generate unique PluginMediaStream and PluginMediaStreamTrack, keep original streamId/trackId for internal calls #447
* Add English facingLabel suffix if localizedName does not match for facing detection using label, fix PluginEnumerateDevices ordered array #446
* Implement PluginRTCAudioController setCategory and use audioMode AVAudioSession.Mode.voiceChat and make initAudioDevices non-static #448
* Fix Callbacks support for getUserMedia ([PR #453](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/453) by @onerinas)

#### Version 6.0.3
* make second argument MediaStream of RTCPeerConnection.prototype.addTrack optional #437
* remove redundant PluginRTCAudioController.initAudioDevices call in getAllAudioDevices causing AVAudioSession to reset to its default settings #439

#### Version 6.0.2
* implement M69 Native RTCPeerConnection.(addTrack|removeTrack) and sdpSemantics unified-plan support #407
* fix insertDtmf #431

#### Version 6.0.1
* fix stopCapture while RTCCameraVideoCapturer is not capturing causing crash due Assertion failure in -[FBSSerialQueue assertOnQueue] #426

#### Version 6.0.0
* Use WebRTC M69
* Use WebRTC.framework
* implement PluginRTCVideoCaptureController with MediaTrackConstraintSet  
* Replace the libwebrtc static lib with the dynamic library from the WebRTC.framework build process using M69 ([PR #399](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/399) by @hthetiot)
* Be able to use minAspectRatio/maxAspectRatio #287
* webrtc/adapter breaks deviceId constraint #282
* Support for facingMode as a video constraint #315
* Capturing a static image from the local MediaStream #116 
* Added Speakerphone funcionality #379
* Restore PluginRTCAudioController including selectAudioOutput and move EnumerateDevice. setPreferredInput| saveAudioDevice into PluginRTCAudioController
* Fix closing and re-opening local stream several times #247
* H264 issues #170
* implement RTCPeerConnectionFactory(encoderFactory, decoderFactory) using getSupportedVideoEncoder to enable VP8 and VP9 #416
* Add Script to manipulate WebRTC binary architectures #421
* Use clean WebRTC.framework build with x86 and ARM support #412
* Decode XML entities in project name in iosrtc-swift-support.js hook #413
* Update travis build to use Xcode 11.0 (11A420a) and iOS 13 support #376
* Generic RTCPeerConnection constraint handling #119 via #394
* Video renders in landscape, but not portrait orientation #360
* Adapter JS change frameRate constraints #286
* Regression switch camera fail (stop stream, remove stream from peer, get stream, add stream to peer, renegociate, fail on m69 but not master)
*  Fix GSM call interrupts the current WebRTC call (Note: Use cordova.plugins.backgroundMode.enable(); on local media Start/Stop).

#### Version 5.0.6
* Decode XML entities in project name in iosrtc-swift-support.js hook  ([PR #413](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/413) by @GProst).

#### Version 5.0.5
* Fix RTCPeerConnection.addTrack when providing stream argument and when multiple tracks are added.
* Handle webrtc-adapter getUserMedia constraints mandatory / optional syntax ([PR #405](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/405) by @hthetiot).
* Restore Callbacks Support on registerGlobals getUserMedia|enumerateDevices RTCPeerConnection.prototype.createAnswer|createOffer|setRemoteDescription|setLocalDescription|addIceCandidate support for JsSIP, SIP.js and sipML5  ([PR #404](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/404) by @hthetiot).
* Update extra/hooks/iosrtc-swift-support.js to be trigger on after_prepare and handle existing SWIFT_OBJC_BRIDGING_HEADER values instead of overiding them ([PR #402](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/402) by @hthetiot).
* Update README.md usages typo and add Requirements about swift-version add npm version badge and travis status badge.

#### Version 5.0.4

* Fix MediaStream.create false positive "ERROR: video track not added" and "ERROR: audio track not added" cause the rtcMediaStream already has them internaly trigger by getUserMedia.
* Detect deprecated callbacks usage and throw Error instead of been silent to assist 5.0.1 to 5.0.2 migration from WebRTC callback RTCPeerConnection.(createOffer|createAnswer|setLocalDescription|setRemoteDescription|addIceCandidate|getStats) and getUserMedia API.
* Reset enumerateDevices videoinput order with front camera first to keep legacy behavior.
* Use safeAreaLayoutGuide for ios 11 and NSLayoutConstraint for ios 10 to fix elementView bad position depending status bar visibility ([PR #367](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/367) by @hthetiot).
* Recognize when a video receives a new srcObject and re-render it ([PR #367](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/395) by @SejH).

#### Version 5.0.3

* Fix MediaStream.active getter issue.
* Fix cordova.plugins.iosrtc.observeVideo MutationObserver issue with srcObject using loadstart and emptied events that does get triggered.
* Add NSBluetoothAlwaysUsageDescription to Info.plist for wireless headphones and microphone consent.
* Deprecate usage of `video.src = URL.createObjectURL(stream)` in favor of `video.srcObject = stream` only MediaStream are not Blob anymore. ([PR #388](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/388) by @hthetiot).
* Update audio input priority to Wired microphone > Wireless microphone > built-in microphone. ([PR #387](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/387) by @CSantosM).
* Add possible missing argument for parameter 'mode' in call on audioSession.setCategory.

#### Version 5.0.2

* Remove WebRTC callback based API for RTCPeerConnection.(createOffer|createAnswer|setLocalDescription|setRemoteDescription|addIceCandidate|getStats) and getUserMedia.
* Set default deployment target to 10.2
* Implement partial RTCPeerConnection.(getSenders|getReceivers|addTrack|removeTrack)
* Fix webrtc-adapter external library support
* Fix Blob prototype pollution
* Extend native MediaStream instead of using Blob
* Fix RTCPeerConnection.setLocalDescription() and other methods which take SDP as input now directly accept an object
* Upgrade packages debug to ^4.1.1 and yaeti to ^1.0.2
* Add cordova.plugins.iosrtc.getUserMedia MediaTrackConstraints.(video|audio).deviceId.(exact|ideal) support ([PR #374](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/374) by @CSantosM).
* Add cordova.plugins.iosrtc.getMediaDevices bluetooth and wired audio devices support ([PR #374](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/374) by @CSantosM).
* fix TypeError: undefined is not an object (evaluating 'stream.id') when removing stream [PR #383](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/383) by @hthetiot via @l7s).

#### Version 5.0.1

* fix typo on iosrtcPlugin.swift

#### Version 5.0.0

* fix README.md
* Convert syntax to Swift 4.2
* Uncomment, and fix, onGetStatsCallback closure
* Update NPM dependencies
* Add Travis build (Ionic, Cordova, Browser, Android, iOS Xcode 10.2)
* Fix gulp browserify caused by old vinyl package version
* Migrate from jscs to eslint to fix vulnerabilities reported by npm audit

#### Version 4.0.2

* `getUserMedia` constraints: Allow `sourceId` (rather than just `deviceId`) to make adapter.js happy (#282).


#### Version 4.0.1

* Let `addIceCandidate()` be called with a `RTCIceCandidateInit` object as argument (as per the latest WebRTC spec) rather than mandating a `RTCIceCandidate` instance.


#### Version 4.0.0

* Moved the repository over to its new home with the Basque VoIP Mafia
* Fix compatibility with "--browserify" cordova option
* Convert syntax to Swift 3
* Remove rtcninja integration
* Remove selectAudioOutput function
* Add convenience Makefile
* Update documentation


#### Version 3.2.2

* Fix promise implementation of RTCPeerConnection.getStats


#### Version 3.2.1

* Fix emitting "connected" stream event for local streams when using getUserMedia with promises.


#### Version 3.2.0

* Add support for RTCPeerConnection.getStats ([PR #163](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/163) by @oNaiPs)

* Set default deployment target to 9.0

* Document iOS 10 specific stuff

* Fix crash if RTCPeerConnection.close() is called twice

* Data channel improvements

* Updated documentation


#### Version 3.1.0

* Implement `RTCPeerConnection.createDTMFSender()` ([PR #189](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/189) by @saghul).

* Make `ios-websocket-hack.js` more reliable.


#### Version 3.0.1

* Fix positioning video elements using `z-index` and allow pure HTML on top of `<video>` elements ([PR #179](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/179) by @saghul and @1N50MN14).
 
* Improve `ios-websocket-hack.js` ([PR #138](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/138) by @apparition47).


#### Version 3.0.0

* Upgrade to `cordova-ios` 4 ([PR #159](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/159) by @apparition47).

* Swift: Use closure syntax for weak and unowned vars ([PR #160](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/160) by @oNaiPs).

* Swift: Sanitize arguments given to `NSLog()` ([issue #157](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/157)).

* `MediaDeviceInfo`: Add deprecated `facing` property ("front", "back" or "unknown") and update `kind` ("audio"/"video" become "audioinput"/"videoinput") ([issue #155](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/155)).

* Update `libwebrtc` to revision 12558 ([issue #169](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/169)).


#### Version 2.2.4

* Fix crash ([issue #144](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/144)).

* Update NPM dependencies.


#### Version 2.2.3

* Enable iOS native H.264 encoder/decoder.

* `RTCDataChannel`: Allow empty `label` ([issue #124](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/124)).

* Update [yaeti](https://www.npmjs.com/package/yaeti) dependency ([issue #123](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/123)).

* Fix retain on `pluginMediaStreamTrack` does not allow camera/mic to be freed ([PR #126](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/126)). Credits to @oNaiPs.

* Allow a handled video element to be removed from the DOM and added again later ([PR #127](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/127)). Credits to @oNaiPs.


#### Version 2.2.2

* Update `libwebrtc` to revision 11063 so `MediaStream` events (`onaddtrack` and `onremovetrack`) work again ([issue #95](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/95)).


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

* Enable CSS padding (thanks to @saghul) ([pull request #89](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/89)).


#### Version 2.0.1

* Don't crash if user or iOS settings deny access lo local audio/video devices ([issue #73](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/73)).


#### Version 2.0.0

* Swift 2.0 is here! Credits to @saghul for his [pull request](https://github.com/cordova-rtc/cordova-plugin-iosrtc/pull/70).
* `extra/hooks/iosrtc-swift-support.js`: Set `BUILD_VERSION` to 7.0.


#### Version 1.4.5

* Add `cordova.plugins.iosrtc.observeVideo(video)` API for the plugin to handle `<video>` elements not yet in the DOM ([issue #49](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/49)).


#### Version 1.4.4

* Support CSS `border-radius` property in HTML video elements.


#### Version 1.4.3

* Make private properties more private ([issue #34](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/34)).


#### Version 1.4.2

* Use [yaeti](https://github.com/ibc/yaeti) module as `EventTarget` shim.


#### Version 1.4.1

* Release `MediaStreamRenderer` and revert `<video>` properties when the attached `MediaStream` emits "inactive" ([issue #27](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/27)).


#### Version 1.4.0

* Implemented some `<video>` properties such as `readyState`, `videoWidth` and `videoHeight` ([issue #25](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/25)).
* Building simplified for both Cordova CLI and Xcode by providing a single ["hook"](extra/hooks/iosrtc-swift-support.js) the user must add into his Cordova application (check the [Building](docs/Building.md) documentation for further details).


#### Version 1.3.3

* CSS `object-fit: none` properly implemented (don't clip the video).


#### Version 1.3.2

* CSS [object-fit](https://css-tricks.com/almanac/properties/o/object-fit/) property implemented in `<video>` elements ([issue #23](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/23)).


#### Version 1.3.1

* Stop "error" event propagation in `<video>` element when attaching a `MediaStream` to it ([issue #22](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/22)).


#### Version 1.3.0

* Plugin moved to [NPM](https://www.npmjs.com/package/cordova-plugin-iosrtc) registry and plugin ID renamed to *cordova-plugin-iosrtc*.


#### Version 1.2.8

* `iosrtc.registerGlobals()` also generates `window.webkitRTCPeerConnection` and `navigator.webkitGetUserMedia()` for backwards compatibility with WebRTC JavaScript wrappers/adapters that assume browser vendor prefixes (`webkit`, `moz`) in the underlying WebRTC API.



