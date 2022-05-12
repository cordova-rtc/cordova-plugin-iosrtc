![cordova-rtc-logo](https://raw.githubusercontent.com/cordova-rtc/cordova-plugin-iosrtc/master/art/cordova-rtc-logo.png)

# cordova-plugin-iosrtc

[![npm version](https://img.shields.io/npm/v/cordova-plugin-iosrtc.svg?style=flat)](https://www.npmjs.com/package/cordova-plugin-iosrtc)
[![Build Status](https://travis-ci.com/cordova-rtc/cordova-plugin-iosrtc.svg?branch=master)](https://travis-ci.com/cordova-rtc/cordova-plugin-iosrtc)

[![NPM](https://nodei.co/npm/cordova-plugin-iosrtc.png)](https://npmjs.org/package/cordova-plugin-iosrtc)

[Cordova](http://cordova.apache.org/) iOS plugin exposing the  ̶f̶u̶l̶l̶ [WebRTC W3C JavaScript APIs](http://www.w3.org/TR/webrtc/).

* [Community Forum](https://github.com/cordova-rtc/cordova-plugin-iosrtc/discussions) for questions and discussions about *cordova-plugin-iosrtc*.
* [Bug Tracker](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues) for reporting issues and requesting new features (**please** don't use the bug tracker for questions or problems, use the mailing list instead).
* [NPM package](https://www.npmjs.com/package/cordova-plugin-iosrtc).


**Yet another WebRTC SDK for iOS?**

Absolutely **not**. This plugin exposes the WebRTC W3C API for Cordova iOS apps (you know there is no WebRTC in iOS, right?), which means no need to learn "yet another WebRTC API" and no need to use a specific service/product/provider.


**Who?**

This plugin was initially developed at eFace2Face, and later maintained by the community, specially by [Saúl Ibarra Corretgé](http://bettercallsaghul.com) (_The OpenSource Warrior Who Does Not Burn_).


## Requirements

In order to make this Cordova plugin run into a iOS application some requirements must be satisfied in both development computer and target devices:

* Xcode >= 13.2.1 (13C100)
* iOS >= 14.3 (run on lower versions at your own risk, don't report issues)
* `swift-version` => 4.2
* `cordova` >= 11.0.0
* `cordova-ios` >= 6.2.0

### Third-Party Supported Library

* WebRTC W3C v1.0.0
* WebRTC.framework => M87
* Janus => 0.7.4
* JSSip => 3.1.2
* Sip.js => 0.15.6
* OpenEasyrtc => 2.0.3
* openvidu => 2.11.0
* Ionic => v8
* Jitsi ~ 3229
* Apizee => 2.6.11
* Twillio => 2.4.0

## Installation

Within your Cordova project:

```bash
$ cordova plugin add cordova-plugin-iosrtc
```

(or add it into a `<plugin>` entry in the `config.xml` of your app).

## Building

* Last [Tested WebRTC.framework](./lib/WebRTC.framework/) version: M87 on cordova-plugin-iosrtc version 8.0.0+
* [Building](docs/Building.md): Guidelines for building a Cordova iOS application including the *cordova-plugin-iosrtc* plugin.
* [Building `libwebrtc`](docs/BuildingLibWebRTC.md): Guidelines for building Google's *libwebrtc* with modifications needed by the *cordova-plugin-iosrtc* plugin (just in case you want to use a different version of *libwebrtc* or apply your own changes to it).

## Sample Application

The `cordova-plugin-iosrtc-sample` include mutiple example for using `cordova-plugin-iosrtc` with JsSip, Janus, EasyRTC, and basic WebSocket Signaling. It's is used to test `cordova-plugin-iosrtc` new release and reproduce reported issues.

- https://github.com/cordova-rtc/cordova-plugin-iosrtc-sample

## Usage

The plugin exposes the `cordova.plugins.iosrtc` JavaScript namespace which contains all the WebRTC classes and functions.

```javascript
/* global RTCPeerConnection */


//
// Container for this sample
//

var appContainer = document.body;
appContainer.innerHTML = "";

//
// Sample getUserMedia
//

//
var localStream, localVideoEl;
function TestGetUserMedia() {
  localVideoEl = document.createElement('video');
  localVideoEl.style.height = "50vh";
  localVideoEl.setAttribute('autoplay', 'autoplay');
  localVideoEl.setAttribute('playsinline', 'playsinline');
  appContainer.appendChild(localVideoEl);

  return navigator.mediaDevices.getUserMedia({
    video: true,
    audio: true
    // Note: Use navigator.mediaDevices.enumerateDevices() Promise to get deviceIds
    /*
    video: {
      // Test Back Camera
      //deviceId: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      //sourceId: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      deviceId: {
        exact: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      }
      // Test FrameRate
      frameRate:{ min: 15.0, max: 30.0 } // Note: Back camera may only support max 30 fps
    },
    audio: {
      deviceId: {
        exact: 'Built-In Microphone'
      }
    }*/
  }).then(function (stream) {

    console.log('getUserMedia.stream', stream);
    console.log('getUserMedia.stream.getTracks', stream.getTracks());

    // Note: Expose for debug
    localStream = stream;

    // Attach local stream to video element
    localVideoEl.srcObject = localStream;

    return localStream;

  }).catch(function (err) {
    console.log('getUserMedia.error', err, err.stack);
  });
}

//
// Sample RTCPeerConnection
//

var pc1, pc2;

var peerConnectionConfig = {
    offerToReceiveVideo: true,
    offerToReceiveAudio: true,
    //iceTransportPolicy: 'relay',
    sdpSemantics: 'unified-plan',
    //sdpSemantics: 'plan-b',
    bundlePolicy: 'max-compat',
    rtcpMuxPolicy: 'negotiate',
    iceServers: [
      {
         urls: ["stun:stun.stunprotocol.org"]
      }
    ]
};

// This plugin handle 'addstream' and 'track' event for MediaStream creation.
var useTrackEvent = Object.getOwnPropertyDescriptors(RTCPeerConnection.prototype).ontrack;

var peerVideoEl, peerStream;
function TestRTCPeerConnection(localStream) {

  pc1 = new RTCPeerConnection(peerConnectionConfig);
  pc2 = new RTCPeerConnection(peerConnectionConfig);

  if (useTrackEvent) {

    // Add local stream tracks to RTCPeerConnection
    var localPeerStream = new MediaStream();
    localStream.getTracks().forEach(function (track) {
      console.log('pc1.addTrack', track, localPeerStream);
      pc1.addTrack(track, localPeerStream);
    });

  // Note: Deprecated but supported
  } else {
     pc1.addStream(localStream);

     // Note: Deprecated Test removeStream
     // pc1.removeStream(pc1.getLocalStreams()[0]);<
  }

  // Basic RTCPeerConnection Local WebRTC Signaling follow.
  function onAddIceCandidate(pc, can) {
    console.log('addIceCandidate', pc, can);
    return can && pc.addIceCandidate(can).catch(function (err) {
      console.log('addIceCandidateError', err);
    });
  }

  pc1.addEventListener('icecandidate', function (e) {
    onAddIceCandidate(pc2, e.candidate);
  });

  pc2.addEventListener('icecandidate', function (e) {
    onAddIceCandidate(pc1, e.candidate);
  });

  function setPeerVideoStream(stream) {

    // Create peer video element
    peerVideoEl = document.createElement('video');
    peerVideoEl.style.height = "50vh";
    peerVideoEl.setAttribute('autoplay', 'autoplay');
    peerVideoEl.setAttribute('playsinline', 'playsinline');
    appContainer.appendChild(peerVideoEl);

    // Note: Expose for debug
    peerStream = stream;

    // Attach peer stream to video element
    peerVideoEl.srcObject = peerStream;
  }

  if (useTrackEvent) {
    var newPeerStream;
    pc2.addEventListener('track', function(e) {
      console.log('pc2.track', e);
      newPeerStream = e.streams[0] || newPeerStream || new MediaStream();
      setPeerVideoStream(newPeerStream);
      newPeerStream.addTrack(e.track);
    });

  // Note: Deprecated but supported
  } else {
    pc2.addEventListener('addstream', function(e) {
      console.log('pc2.addStream', e);
      setPeerVideoStream(e.stream);
    });
  }

  pc1.addEventListener('iceconnectionstatechange', function (e) {
    console.log('pc1.iceConnectionState', e, pc1.iceConnectionState);

    if (pc1.iceConnectionState === 'completed') {
      console.log('pc1.getSenders', pc1.getSenders());
      console.log('pc2.getReceivers', pc2.getReceivers());
    }
  });

  pc1.addEventListener('icegatheringstatechange', function (e) {
    console.log('pc1.iceGatheringStateChange', e);
  });

  pc1.addEventListener('negotiationneeded', function (e) {
    console.log('pc1.negotiatioNeeded', e);

    return pc1.createOffer().then(function (d) {
      var desc = {
        type: d.type,
        sdp: d.sdp
      };
      console.log('pc1.setLocalDescription', desc);
      return pc1.setLocalDescription(desc);
    }).then(function () {
      var desc = {
        type: pc1.localDescription.type,
        sdp: pc1.localDescription.sdp
      };
      console.log('pc2.setLocalDescription', desc);
      return pc2.setRemoteDescription(desc);
    }).then(function () {
      console.log('pc2.createAnswer');
      return pc2.createAnswer();
    }).then(function (d) {
      var desc = {
        type: d.type,
        sdp: d.sdp
      };
      console.log('pc2.setLocalDescription', desc);
      return pc2.setLocalDescription(d);
    }).then(function () {
      var desc = {
        type: pc2.localDescription.type,
        sdp: pc2.localDescription.sdp
      };
      console.log('pc1.setRemoteDescription', desc);
      return pc1.setRemoteDescription(desc);
    }).catch(function (err) {
      console.log('pc1.createOffer.error', err);
    });
  });
}

function TestRTCPeerConnectionLocal() {

  // Note: This allow this sample to run on any Browser
  var cordova = window.cordova;
  if (cordova && cordova.plugins && cordova.plugins.iosrtc) {

    // Expose WebRTC and GetUserMedia SHIM as Globals (Optional)
    // Alternatively WebRTC API will be inside cordova.plugins.iosrtc namespace
    cordova.plugins.iosrtc.registerGlobals();

    // Enable iosrtc debug (Optional)
    cordova.plugins.iosrtc.debug.enable('*', true);
  }

  // Run sample
  TestGetUserMedia().then(function (localStream) {
    TestRTCPeerConnection(localStream);
  });
}

if (document.readyState === "complete" || document.readyState === "loaded") {
  TestRTCPeerConnectionLocal();
} else {
  window.addEventListener("DOMContentLoaded", TestRTCPeerConnectionLocal);
}

// See ./extra/renderer-and-libwebrtc-tests.js for more samples usage.
```

In case you'd like to expose the API in the global namespace like regular browsers you can do the following:

```javascript
// Just for Cordova apps.
document.addEventListener('deviceready', function () {
  // Just for iOS devices.
  if (window.device.platform === 'iOS') {
    cordova.plugins.iosrtc.registerGlobals();

    // load adapter.js
    var adapterVersion = 'latest';
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "https://webrtc.github.io/adapter/adapter-" + adapterVersion + ".js";
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

Don't call plugin methods within WebSocket events (`onopen`, `onmessage`, etc). There is an issue in iOS Safari (see [issue #12](https://github.com/cordova-rtc/cordova-plugin-iosrtc/issues/12)). Instead run a `setTimeout()` within the WebSocket event if you need to call plugin methods on it.

Or better yet, include the provided [ios-websocket-hack.js](extra/ios-websocket-hack.js) in your app and load into your `index.html` as follows:

```
<script src="cordova.js"></script>
<script src="ios-websocket-hack.min.js"></script>
```

#### HTML5 video API

There is no real media source attached to the `<video>` element so some [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events) and properties are artificially emitted/set by the plugin on behalf of the video element.

Methods such as `play()`, `pause()` are not implemented. In order to pause a video just set `enabled = false` on the associated `MediaStreamTrack`.

#### iOS >= 13.3.1 Device support

To run on Devices with iOS >= 13.3.1, you need a valid Apple Developer account to sign the WebRTC dynamic frameworks for more info see https://stackoverflow.com/a/60090629/8691951

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).


## Authors

* [Iñaki Baz Castillo](https://inakibaz.me) (no longer active maintainer)
* [Saúl Ibarra Corretgé](http://bettercallsaghul.com) (no longer active maintainer)
* [Harold Thetiot](https://sylaps.com)


### Maintainer

* [Harold Thetiot](https://sylaps.com)

**If you like this project you can support me.**

<a href="https://www.buymeacoffee.com/hthetiot" target="_blank">
	<img src="https://cdn.buymeacoffee.com/buttons/default-white.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" >
</a>

## License

[MIT](./LICENSE) :)
