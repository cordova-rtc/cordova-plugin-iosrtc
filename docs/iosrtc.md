# `iosrtc` API

The top level `iosrtc` module is a JavaScript Object containing all the exposes WebRTC classes and functions along with other utilities.

The `iosrtc` module is exposed within the `window.cordova.plugins` namespace (Cordova plugins convention).


### `iosrtc.getUserMedia()`

Implementation of the  `getUserMedia()` function as specified by the [W3C Media Capture and Streams draft](http://w3c.github.io/mediacapture-main/#local-content).

The function allows both the old/decrecated callbacks based syntax and the new one based on Promises (depending on the number and type of the given arguments).

*NOTE:* In iOS devices there is a single audio input (mic) and two video inputs (camera). If the given constraints include "video" the device chosen by default is the front camera. However the back camera can be chosen by passing an "optional" or "mandatory" constraint to the function:

```javascript
cordova.plugins.iosrtc.getUserMedia({
  audio: true,
  video: {
    optional: [
      { sourceId: 'com.apple.avfoundation.avcapturedevice.built-in_video:1' }
    ]
  }
});
```

*NOTE:* The API to select a specific device is outdated, but it matches the one currently implemented by Chrome browser.

*TODO:*

* Rich constraints.


### `iosrtc.getMediaDevices()`

Implementation of the  `enumerateDevices()` function as specified in the [W3C Media Capture and Streams draft](http://w3c.github.io/mediacapture-main/#enumerating-devices).

The function allows both the old/decrecated callbacks based syntax and the new one based on Promises.

The success callback is called with a list of `MediaDeviceInfo` objects as defined in the same spec. However such an object includes deprecated fields for backwards compatibility. The read-only fields in a `MediaDeviceInfo` object are:

* `deviceId` (String)
* `kind` (String)
* `label` (String)
* `groupId` (always an empty string)
* `id` (same as `deviceId`, deprecated)
* `facing` (always an empty string, deprecated)

*NOTE:* The `deviceId` or `id` field is the value to be used in the `sourceId` field of `getUserMedia()` above to choose a specific device.


### `iosrtc.RTCPeerConnection`

Exposes the `RTCPeerConnection` class as defined by the [W3C Real-time Communication Between Browsers draft](http://www.w3.org/TR/webrtc/#rtcpeerconnection-interface).

All the methods are implemented in both fashions: the deprecated callbacks based syntax and the new one based on Promises.

*TODO:*

* `updateIce()` method.
* `getStats()` method.
* Cannot use `id` value greater than 1023 in the config object for `createDataChannel()` (see [issue #4618](https://code.google.com/p/webrtc/issues/detail?id=4618)).


###  `iosrtc.RTCSessionDescription`

Exposes the `RTCSessionDescription` class as defined by the [spec](http://www.w3.org/TR/webrtc/#idl-def-RTCSessionDescription).


### `iosrtc.RTCIceCandidate`

Exposes the `RTCIceCandidate` class as defined by the [spec](http://www.w3.org/TR/webrtc/#idl-def-RTCIceCandidate).


### `iosrtc.MediaStreamTrack`

Exposes the `MediaStreamTrack` class as defined by the [spec](http://w3c.github.io/mediacapture-main/#mediastreamtrack).

*NOTE:* The only reason to make this class public is to expose the deprecated `MediaStreamTrack.getSources()` class function, which is an "alias" to the `getMediaDevices()` function described above.

*TODO:*

* `muted` attribute (not exposed by the Objective-C wrapper of the Google WebRTC library).
* `onmute` and `onunmute` events.
* `clone()` methods.
* `getCapabilities()` method.
* `getConstraints()` method.
* `getSettings()` method.
* `applyConstraints()` method.
* `onoverconstrained` event.


### `iosrtc.MediaStreamRenderer`

See the [`MediaStreamRenderer` API](https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/MediaStreamRenderer.md).


### `iosrtc.debug`

The [debug](https://github.com/visionmedia/debug) module. Useful to enable verbose logging:

```javascript
cordova.plugins.iosrtc.debug('iosrtc*');
```


### `iosrtc.rtcninjaPlugin`

A plugin interface for [rtcninja](https://github.com/eface2face/rtcninja.js/). 

Usage (assuming that [Cordova Device Plugin](http://plugins.cordova.io/#/package/org.apache.cordova.device) is installed):

```javascript
document.addEventListener('deviceready', function () {
  // Just for iOS devices.
  if (window.cordova && window.device.platform === 'iOS') {
    rtcninja({plugin: cordova.plugins.iosrtc.rtcninjaPlugin});
  }

  console.log('WebRTC supported?: %s', rtcninja.hasWebRTC());
  // => WebRTC supported?: true

  rtcninja.RTCPeerConnection === cordova.plugins.iosrtc.RTCPeerConnection;
  // => true
});
```



## Others


### `MediaStream`

The `MediaStream` class (as defined in the [spec](http://w3c.github.io/mediacapture-main/#mediastream)) is not directly exposed by `iosrtc` via public API. Instead an instance of `MediaStream` is given within `onaddstream` / `onremovestream` events or the success callback of `getUserMedia()`.

*NOTES:*

* `stop()` method implemented for backwards compatibility (it calls `stop()` on all its `MediaStreamTracks`).

*TODO:*

* `clone()` method.
* No `onaddtrack` / `onremovetrack` events due to a limitation in the Objective-C wrapper (see [issue #4640](https://code.google.com/p/webrtc/issues/detail?id=4640)).


### `RTCDataChannel`

The `RTCDataChannel` class (as defined in the [spec](http://www.w3.org/TR/webrtc/#idl-def-RTCDataChannel)) is not directly exposed by `iosrtc` via public API. Instead an instance of `RTCDataChannel` is returned by `createDataChannel()` and provided by the `ondatachannel` event.

The full DataChannel API is implemented (including binary messages).

*TODO:*

* `binaryType` just accepts `arraybuffer` (same as Chrome browser).
* Cannot read the `protocol` field of a `RTCDataChannel` (see [issue #4614](https://code.google.com/p/webrtc/issues/detail?id=4614)).
