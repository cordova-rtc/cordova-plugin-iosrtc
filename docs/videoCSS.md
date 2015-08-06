# `<video>` CSS

The plugin places a native [UIView](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/) on top of all those HTML `<video>` elements in which a WebRTC `MediaStream` has been attached.

The plugin inspects the CSS properties of the `<video>` element and uses them to make the video `UIView` behave similary.

Supported CSS properties are:

* `display`
* `opacity`
* `visibility`
* `z-index`: Useful to place a video on top of another video.
* [`object-fit`](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit)
* `-webkit-transform: scaleX(-1)`: Useful for horizontal mirror effect.
