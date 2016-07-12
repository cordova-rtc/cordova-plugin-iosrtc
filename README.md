# cordova-plugin-iosrtc

[Cordova](http://cordova.apache.org/) iOS plugin exposing the full [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).


* [Public Google Group (mailing list)](https://groups.google.com/forum/#!forum/cordova-plugin-iosrtc) for questions and discussions about *cordova-plugin-iosrtc*.
* [Bug Tracker](https://github.com/eface2face/cordova-plugin-iosrtc/issues) for reporting issues and requesting new features (**please** don't use the bug tracker for questions or problems, use the mailing list instead).
* [NPM package](https://www.npmjs.com/package/cordova-plugin-iosrtc).


**Yet another WebRTC SDK for iOS?**

Absolutely **not**. This plugin exposes the WebRTC W3C API for Cordova iOS apps (you know there is no WebRTC in iOS, right?), which means no need to learn "yet another WebRTC API" and no need to use a specific service/product/provider. 

**Why?**

Check the [release announcement](https://eface2face.com/blog/cordova-plugin-iosrtc.html) at the [eFace2Face](https://eface2face.com) site.


## Requirements

In order to make this Cordova plugin run into a iOS application some requirements must be satisfied in both development computer and target devices:

* Xcode >= 7.2.1
* iOS >= 9 (run on lower versions at your own risk, but don't report issues)
* `cordova-ios` 4.X
* No bitcode (built-in *libwebrtc* does not contain bitcode so you need to disable it in your Xcode project settings)


## Installation

Within your Cordova project:

```bash
$ cordova plugin add cordova-plugin-iosrtc
```

(or add it into a `<plugin>` entry in the `config.xml` of your app).


## Building

* [Building](docs/Building.md): Guidelines for building a Cordova iOS application including the *cordova-plugin-iosrtc* plugin.
* [Building `libwebrtc`](docs/BuildingLibWebRTC.md): Guidelines for building Google's *libwebrtc* with modifications needed by the *cordova-plugin-iosrtc* plugin (just in case you want to use a different version of *libwebrtc* or aplpy your own changes to it).


## Usage

The plugin exposes the `cordova.plugins.iosrtc` JavaScript namespace which contains all the WebRTC classes and functions.

```javascript
var pc = new cordova.plugins.iosrtc.RTCPeerConnection({
  iceServers: []
});

cordova.plugins.iosrtc.getUserMedia(
  // constraints
  { audio: true, video: true },
  // success callback
  function (stream) {
    console.log('got local MediaStream: ', stream);

    pc.addStream(stream);
  },
  // failure callback
  function (error) {
    console.error('getUserMedia failed: ', error);
  }
);
```

**Q:** But... wait! Does it mean that there is no `window.RTCPeerConnection` nor `navigator.getUserMedia`?

**R:** A Cordova plugin is supposed to expose its JavaScript stuff in a specific namespace and, personally, I just hate those libraries that pollute the global namespace. Said that, the plugin provides a `registerGlobals()` method, so you just need the following extra-code in your existing WebRTC app (assuming that [cordova-plugin-device](https://www.npmjs.com/package/cordova-plugin-device) is installed):

```javascript
// Just for Cordova apps.
document.addEventListener('deviceready', function () {
  // Just for iOS devices.
  if (window.device.platform === 'iOS') {
    cordova.plugins.iosrtc.registerGlobals();
  }
});
```

And that's all. Now you have `window.RTCPeerConnection`, `navigator.getUserMedia`, etc.

**Q:** What about `<video>` elements and `video.src = URL.createObjectURL(stream)`? do I need custom HTML tags or functions to display WebRTC videos?

**R:** No. Just use an HTML video element as usual, really. The plugin will properly place a native *UIView* layer on top of it by respecting (most of) its [CSS properties](docs/videoCSS.md).

**Q:** Can I place HTML elements (buttons and so on) on top of active `<video>` elements?

**R:** Yes. See the [<video> CSS](docs/videoCSS.md) documentation.

**Q:** What about [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events)? Can I rely on `video.oncanplay`?

**R:** I see what you mean. As there is no real video attached to the `<video>` element, media events are artificially emitted by the plugin. The following events are emitted when the `MediaStream` attached to a video element is ready to render video: `onloadedmetadata`, `onloadeddata`, `oncanplay`, `oncanplaythrough`. So yes, you can rely on them.

**Q:** Can I read `<video>` properties such as `readyState`, `videoWidth`, etc?

Again, there is no real video attached to the `<video>` element so some peroperties are artificially set by the plugin. These are `readyState`, `videoWidth` and `videoHeight`.

**Q:** Do I need to call special methods to release/free native WebRTC objects? How are they garbage collected?

**R:** Good question. An `RTCPeerConnection` is released when `close()` is called on it, a `MediaStream` is released when all its tracks end, and other elements are garbage collected when no longer needed. Basically the same behavior as in a WebRTC capable browser.

**Q:** What about Android? Why just iOS?

**R:** In modern versions of Android the *WebView* component is based on the Chromium open source project which already includes WebRTC ([more info](https://developer.chrome.com/multidevice/webview/overview)). For older versions of Android the [CrossWalk](https://crosswalk-project.org) project provides new *WebView* versions with WebRTC support as well.


## Documentation

Read the full [documentation](docs/index.md) in the *docs* folder.


## Demo Application

Check our [iOSRTCApp](https://github.com/eface2face/iOSRTCApp) (Google's [AppRTC](https://apprtc.appspot.com/) adapted to Cordova iOS with pure HTML5/JavaScript and *cordova-plugin-iosrtc*).

*NOTE:* The demo app is currently unmaintained and it may just fail.


## Who Uses It

[People and companies](WHO_USES_IT.md) using *cordova-plugin-iosrtc*.

If you are using the plugin we would love to [heard back from you](WHO_USES_IT.md)!


## Known Issues


#### iOS Safari and crash on WebSocket events

Don't call plugin methods within WebSocket events (`onopen`, `onmessage`, etc). There is an issue in iOS Safari (see [issue #12](https://github.com/eface2face/cordova-plugin-iosrtc/issues/12)). Instead run a `setTimeout()` within the WebSocket event if you need to call plugin methods on it.

Or better yet, include the provided [ios-websocket-hack.js](extra/ios-websocket-hack.js) in your app and load into your `index.html` as follows:

```
<script src="cordova.js"></script>
<script src="ios-websocket-hack.min.js"></script>
```

#### HTML5 video API

As explained above, there is no real media source attached to the `<video>` element so some [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events) and properties are artificially emitted/set by the plugin on behalf of the video element.

Methods such as `play()`, `pause()` are not implemented. In order to pause a video just set `enabled = false` on the associated `MediaStreamTrack`.


## Changelog


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


## Author

Iñaki Baz Castillo at [eFace2Face, inc.](https://eface2face.com)


## License

[MIT](./LICENSE) :)
