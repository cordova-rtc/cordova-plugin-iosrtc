# cordova-plugin-iosrtc

[Cordova](http://cordova.apache.org/) iOS plugin exposing the full [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).

**Yet another WebRTC SDK for iOS?**

Absolutely **not**. This plugin exposes the WebRTC W3C API for Cordova iOS apps (you know there is no WebRTC in iOS, right?), which means no need to learn "yet another WebRTC API" and no need to use a specific service/product/provider. 

**Why?**

Check the [release announcement](https://eface2face.com/blog/cordova-plugin-iosrtc.html) at the [eFace2Face](https://eface2face.com) site.

**Resources:**

* [NPM package](https://www.npmjs.com/package/cordova-plugin-iosrtc).
* [Public Google Group](https://groups.google.com/forum/?hl=es#!forum/cordova-plugin-iosrtc) for questions and discussions about *cordova-plugin-iosrtc*.
* [Bug Tracker](https://github.com/eface2face/cordova-plugin-iosrtc/issues) for reporting issues and requesting new features (please don't use the bug tracker for questions or problems, use the Google Group instead).


## Installation

Within your Cordova project:

```bash
$ cordova plugin add cordova-plugin-iosrtc
```

(or add it into a `<plugin>` entry in the `config.xml` of your app).


## Building

This plugin needs [Swift](https://developer.apple.com/swift/) support so some steps are needed to get your project working with it. These steps are explained in the [Building](docs/Building.md) documentation, please check it.

**IMPORTANT:** It seems that the incoming [Swift 2.0](https://developer.apple.com/swift/blog/?id=29) (included in the next OS X [El Capitan](https://developer.apple.com/osx/pre-release/)) requires code changes for the plugin to compile. It will be addressed in [issue #28](https://github.com/eface2face/cordova-plugin-iosrtc/issues/28).


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

**R:** No. Just use an HTML video element as usual, really. The plugin will properly place a native *UIView* layer on top of it by respecting (most of) its [CSS properties](videoCSS.md).

**Q:** Can I place HTML elements (buttons and so on) on top of active `<video>` elements?

**R:** Not yet, but there is ongoing work to enable this feature (see [here](https://github.com/eface2face/cordova-plugin-iosrtc/issues/38)).

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


## Demo application

Check our [iOSRTCApp](https://github.com/eface2face/iOSRTCApp) (Google's [AppRTC](https://apprtc.appspot.com/) adapted to Cordova iOS with pure HTML5/JavaScript and *cordova-plugin-iosrtc*).


## Who Uses It

[People and companies](WHO_USES_IT.md) using *cordova-plugin-iosrtc*.

If you are using the plugin we would love to [heard back from you](WHO_USES_IT.md)!


## Known Issues


#### iOS Safari and crash on WebSocket events

Don't call plugin methods within WebSocket events (`onopen`, `onmessage`, etc). There is an issue in iOS Safari (see [issue #12](https://github.com/eface2face/cordova-plugin-iosrtc/issues/12)). Instead run a `setTimeout()` within the WebSocket event if you need to call plugin methods on it.

Or better, just load the provided [ios-websocket-hack.js](extra/ios-websocket-hack.js) script into your Cordova iOS app and you are done.


#### HTML5 video API

As explained above, there is no real media source attached to the `<video>` element so some [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events) and properties are artificially emitted/set by the plugin on behalf of the video element.

Methods such as `play()`, `pause()` are not implemented. In order to pause a video just set `enabled = false` on the associated `MediaStreamTrack`.


## Changelog

(since version 1.2.8)

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
