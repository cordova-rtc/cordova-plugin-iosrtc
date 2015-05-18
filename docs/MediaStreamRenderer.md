# `MediaStreamRenderer` API

The way in which a video `MediaStreamTrack` can be displayed when running Cordova on iOS devices is by creating a native `UIView` layer to render the video track.

The `MediaStreamRenderer` class (exposed by `window.cordova.plugins.iosrtc.MediaStreamRenderer`) provides an object for managing both the media stream and the HTML5 `<video>` element in which the video must be displayed.


### `renderer = new MediaStreamRenderer(element)`

Creates a new instance of `MediaStreamRenderer` associated to the given HTML5 `<video>` tag element. A native `UIView` layer is created on top of the given HTML5 element (properties such as the CSS "opacity", "visibility" or "z-index" of the HTML5 element are properly translated into the `UIView` layer.

```javascript
var remoteVideoElement = document.querySelector('#remoteVideo');
var remoteVideoRenderer = new cordova.plugins.iosrtc.MediaStreamRenderer(remoteVideoelement);

peerconnection.addEventListener('addstream', function (data) {
  localVideoRenderer.render(data.stream);
});

peerconnection.addEventListener('signalingstatechange', function () {
  if (peerconnection.signalingState === 'closed') {
    localVideoRenderer.close();
  }
});
```


### `renderer.render(stream)`

If the given `MediaStream` instance contains a video `MediaStreamTrack` it is displayed in the HTML5 element of the renderer instance.

Can be called many times (the previous stream is just removed).


### `renderer.refresh()`

The height/width, opacity, visibility and z-index of the HTML5 element are recomputed and the `UIView` layer updated according.

Call this method when the position or size of the video element change.


### `videoresize` event

The `MediaStreamRenderer` implements the `EventTarget` interface and fires a `videoresize` event when the exact resolution of the rendering video are known or change.

```javascript
renderer.addEventListener('videoresize', function (event) {
  console.log('video size: %d x %d', event.videoWidth, event.videoHeight);
});
```
