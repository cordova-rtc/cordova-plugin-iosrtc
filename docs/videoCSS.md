# `<video>` CSS

The plugin places a native [UIView](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/) on top of all those HTML `<video>` elements in which a WebRTC `MediaStream` has been attached.

The plugin inspects the CSS properties of the `<video>` element and uses them to make the video `UIView` behave similary.

Supported CSS properties are:

* `display`
* `opacity`
* `visibility`
* `padding`
* `z-index`: Useful to place a video on top of another video.
* [`object-fit`](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit)
* `-webkit-transform: scaleX(-1)`: Useful for horizontal mirror effect.

**Note**: if the specified z-index is < 0 (that, is, the video elements will be positioned "behind" the web view), you should specify the
`<body>` `background-color` as `transparent` so the video element will be seen through the web view. This makes it possible to position
HTML elements on top of the native video elements.

## Quirks

### Position of the `WebView` element does not match the corresponding `video` element

In some cases iOS adds an offset to the `WebView` element. As a result the coordinates between the `video` element and it's corresponding `WebView` element are out of sync.
This happens when the status bar is shown. This can be fixed through disabling the statusbar in two ways:

* at runtime, using [cordova-plugin-statusbar](https://github.com/apache/cordova-plugin-statusbar)
* permanently, editing the project `.plist` file:
```xml
  <key>UIViewControllerBasedStatusBarAppearance</key>
  <false/>
  <key>UIStatusBarHidden</key>
  <true/>
```
