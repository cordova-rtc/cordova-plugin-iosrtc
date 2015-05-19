# cordova-plugin-iosrtc

[Cordova](http://cordova.apache.org/) iOS plugin exposing the full [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).

* Cordova Plugins Registry: http://plugins.cordova.io/#/package/com.eface2face.iosrtc


## Installation

Within your Cordova project:

```bash
$ cordova plugin add com.eface2face.iosrtc
```


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

**R:** A Cordova plugin is supposed to expose its JavaScript stuff in a specific namespace, and personally, I just hate those libraries that pollute the global namespace. Said that, the plugin provides a `polluteGlobals()` method, so you just need the following extra-code in your app (assuming that [Cordova Device Plugin](http://plugins.cordova.io/#/package/org.apache.cordova.device) is installed):

```javascript
// Just for Cordova apps.
document.addEventListener('deviceready', function () {
  // Just for iOS devices.
  if (window.device.platform === 'iOS') {
    cordova.plugins.iosrtc.polluteGlobals();
  }
});
```

And that's all. Now you have `window.RTCPeerConnection`, `navigator.getUserMedia`, etc.


## Documentation

Read the full [API documentation](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/index.md) in the *docs* folder.


## Author

Iñaki Baz Castillo at [eFace2Face, inc.](http://eface2face.com)


## License

[MIT](./LICENSE)
