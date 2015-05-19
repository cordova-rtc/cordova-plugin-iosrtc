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



## Documentation

Read the full [API documentation](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/index.md) in the *docs* folder.


## Author

Iñaki Baz Castillo at [eFace2Face, inc.](http://eface2face.com)


## License

[MIT](./LICENSE)
