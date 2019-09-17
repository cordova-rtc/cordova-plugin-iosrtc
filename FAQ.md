# FAQ

**Q:** What about `<video>` elements and `video.srcObject = stream`? do I need custom HTML tags or functions to display WebRTC videos?

**A:** No. Just use an HTML video element as usual, really. The plugin will properly place a native *UIView* layer on top of it by respecting (most of) its [CSS properties](docs/videoCSS.md).

**Q:** Can I place HTML elements (buttons and so on) on top of active `<video>` elements?

**A:** Yes. See the [<video> CSS](docs/videoCSS.md) documentation.

**Q:** What about [HTML5 video events](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events)? Can I rely on `video.oncanplay`?

**A:** I see what you mean. As there is no real video attached to the `<video>` element, media events are artificially emitted by the plugin. The following events are emitted when the `MediaStream` attached to a video element is ready to render video: `onloadedmetadata`, `onloadeddata`, `oncanplay`, `oncanplaythrough`. So yes, you can rely on them.

**Q:** Can I read `<video>` properties such as `readyState`, `videoWidth`, etc?

**A:** Again, there is no real video attached to the `<video>` element so some peroperties are artificially set by the plugin. These are `readyState`, `videoWidth` and `videoHeight`.

**Q:** Do I need to call special methods to release/free native WebRTC objects? How are they garbage collected?

**A:** Good question. An `RTCPeerConnection` is released when `close()` is called on it, a `MediaStream` is released when all its tracks end, and other elements are garbage collected when no longer needed. Basically the same behavior as in a WebRTC capable browser.

**Q:** What about Android? Why just iOS?

**A:** In modern versions of Android the *WebView* component is based on the Chromium open source project which already includes WebRTC ([more info](https://developer.chrome.com/multidevice/webview/overview)). For older versions of Android the [CrossWalk](https://crosswalk-project.org) project provides new *WebView* versions with WebRTC support as well.

**Q:** Why does a "play button" show up on top of the video?

**A:** That's automatically done by Safari, you can disable it by using the following CSS rules:
```css
video::-webkit-media-controls {
    display: none !important;
}
video::-webkit-media-controls-start-playback-button {
    display: none !important;
}
```
