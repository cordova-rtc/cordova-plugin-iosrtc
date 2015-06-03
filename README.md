# cordova-plugin-iosrtc

[Cordova](http://cordova.apache.org/) iOS plugin exposing the full [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).

*Why?* Check the [release announcement](https://eface2face.com/blog/cordova-plugin-iosrtc.html) at the [eFace2Face](https://eface2face.com) site.

* [Plugin entry](http://plugins.cordova.io/#/package/com.eface2face.iosrtc) at the Apache Cordova Plugins Registry.
* [Public Google Group](https://groups.google.com/forum/?hl=es#!forum/cordova-plugin-iosrtc) for questions and discussions about *cordova-plugin-iosrtc*.
* [Bug Tracker](https://github.com/eface2face/cordova-plugin-iosrtc/issues) for reporting issues and requesting new features (please don't use the bug tracker for questions or problems, use the Google Group instead).

**IMPORTANT:** Ensure you check the proper documentation according to the exact version of the *cordova-plugin-iosrtc* plugin you have installed. On GitHub go to the top of this page and select the appropriate *tag* within the "branch"/"tag" selector and make it match the plugin version.


## Installation

Within your Cordova project:

```bash
$ cordova plugin add com.eface2face.iosrtc
```


## Building

If you just use the `cordova-cli` to manage and build your Cordova project then you are done with the usual commans (`cordova build ios`, etc).

If you build your Cordova application using Xcode then some steps must be done as explained in the [documentation](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/Building.md).


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

**R:** A Cordova plugin is supposed to expose its JavaScript stuff in a specific namespace and, personally, I just hate those libraries that pollute the global namespace. Said that, the plugin provides a `registerGlobals()` method, so you just need the following extra-code in your existing WebRTC app (assuming that [Cordova Device Plugin](http://plugins.cordova.io/#/package/org.apache.cordova.device) is installed):

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

**R:** No. Just use an HTML video element as usual, really. The plugin will properly place a native `UIView` layer on top of it by respecting its properties such as the CSS `display`, `opacity`, `visibility`, `z-index` and also horizontal mirror effect with `-webkit-transform: scaleX(-1);`.

**Q:** Do I need to call special methods to release/free native WebRTC objects? How are they garbage collected?

**R:** Good question. An `RTCPeerConnection` is released when `close()` is called on it, a `MediaStream` is released when all its tracks end, and other elements are garbage collected when no longer needed. Basically the same behavior as in a WebRTC capable browser.

**Q:** What about Android? Why just iOS?

**R:** In modern versions of Android the *WebView* component is based on the Chromium open source project which already includes WebRTC ([more info](https://developer.chrome.com/multidevice/webview/overview)). For older versions of Android the [CrossWalk](https://crosswalk-project.org) project provides new *WebView* versions with WebRTC support as well.


## Documentation

Read the full [documentation](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/index.md) in the *docs* folder.


## Known Issues

### iOS Safari and crash on WebSocket events

Don't call plugin methods within WebSocket events (`onopen`, `onmessage`, etc). There is an issue in iOS Safari (see [issue #12](https://github.com/eface2face/cordova-plugin-iosrtc/issues/12)). Instead run a `setTimeout()` within the WebSocket event if you need to call plugin methods on it.

Or better, just load the provided [ios-websocket-hack.js](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/extra/ios-websocket-hack.js) script into your Cordova iOS app.


## Author

Iñaki Baz Castillo at [eFace2Face, inc.](https://eface2face.com)


## License

[MIT](./LICENSE) :)
