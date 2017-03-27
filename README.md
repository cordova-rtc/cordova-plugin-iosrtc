# cordova-plugin-iosrtc

[Cordova](http://cordova.apache.org/) iOS plugin exposing the full [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).


* [Public Google Group (mailing list)](https://groups.google.com/forum/#!forum/cordova-plugin-iosrtc) for questions and discussions about *cordova-plugin-iosrtc*.
* [Bug Tracker](https://github.com/BasqueVoIPMafia/cordova-plugin-iosrtc/issues) for reporting issues and requesting new features (**please** don't use the bug tracker for questions or problems, use the mailing list instead).
* [NPM package](https://www.npmjs.com/package/cordova-plugin-iosrtc).


**Yet another WebRTC SDK for iOS?**

Absolutely **not**. This plugin exposes the WebRTC W3C API for Cordova iOS apps (you know there is no WebRTC in iOS, right?), which means no need to learn "yet another WebRTC API" and no need to use a specific service/product/provider.

**Why?**

Check the [release announcement](https://eface2face.com/blog/cordova-plugin-iosrtc.html) at the [eFace2Face](https://eface2face.com) site.


**Who?**

This plugin was initially developed at [eFace2Face](https://eface2face.com), and later maintained by the community, specially by [Saúl Ibarra Corretgé](http://bettercallsaghul.com) (_The OpenSource Warrior Who Does Not Burn_).


## Requirements

In order to make this Cordova plugin run into a iOS application some requirements must be satisfied in both development computer and target devices:

* Xcode >= 7.2.1
* iOS >= 9 (run on lower versions at your own risk, but don't report issues)
* `cordova-ios` 4.X


## Installation

Within your Cordova project:

```bash
$ cordova plugin add cordova-plugin-iosrtc
```

(or add it into a `<plugin>` entry in the `config.xml` of your app).


## Building

* [Building](docs/Building.md): Guidelines for building a Cordova iOS application including the *cordova-plugin-iosrtc* plugin.
* [Building `libwebrtc`](docs/BuildingLibWebRTC.md): Guidelines for building Google's *libwebrtc* with modifications needed by the *cordova-plugin-iosrtc* plugin (just in case you want to use a different version of *libwebrtc* or apply your own changes to it).


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

In case you'd like to expose the API in the global namespace like regular browsers you can do the following:

```javascript
// Just for Cordova apps.
document.addEventListener('deviceready', function () {
  // Just for iOS devices.
  if (window.device.platform === 'iOS') {
    cordova.plugins.iosrtc.registerGlobals();

    // load adapter.js
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "js/adapter-latest.js";
    script.async = false;
    document.getElementsByTagName("head")[0].appendChild(script);
  }
});
```

And that's all. Now you have `window.RTCPeerConnection`, `navigator.getUserMedia`, etc.


## FAQ

See [the FAQ](FAQ.md).


## Documentation

Read the full [documentation](docs/index.md) in the *docs* folder.


## Who Uses It

[People and companies](WHO_USES_IT.md) using *cordova-plugin-iosrtc*.

If you are using the plugin we would love to [hear back from you](WHO_USES_IT.md)!


## Known Issues


#### iOS Safari and crash on WebSocket events

Don't call plugin methods within WebSocket events (`onopen`, `onmessage`, etc). There is an issue in iOS Safari (see [issue #12](https://github.com/BasqueVoIPMafia/cordova-plugin-iosrtc/issues/12)). Instead run a `setTimeout()` within the WebSocket event if you need to call plugin methods on it.

Or better yet, include the provided [ios-websocket-hack.js](extra/ios-websocket-hack.js) in your app and load into your `index.html` as follows:

```
<script src="cordova.js"></script>
<script src="ios-websocket-hack.min.js"></script>
```

#### HTML5 video API

There is no real media source attached to the `<video>` element so some [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events) and properties are artificially emitted/set by the plugin on behalf of the video element.

Methods such as `play()`, `pause()` are not implemented. In order to pause a video just set `enabled = false` on the associated `MediaStreamTrack`.


## Changelog

See [CHANGELOG.md](./CHANGELOG.md).


## Author

[Iñaki Baz Castillo](https://inakibaz.me/)


### Maintainers

* [Iñaki Baz Castillo](https://inakibaz.me/)
* [Saúl Ibarra Corretgé](http://bettercallsaghul.com)


## License

[MIT](./LICENSE) :)
