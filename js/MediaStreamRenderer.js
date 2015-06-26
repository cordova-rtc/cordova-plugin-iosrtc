/**
 * Expose the MediaStreamRenderer class.
 */
module.exports = MediaStreamRenderer;


/**
 * Dependencies.
 */
var
	debug = require('debug')('iosrtc:MediaStreamRenderer'),
	exec = require('cordova/exec'),
	randomNumber = require('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = require('./EventTarget'),
	MediaStream = require('./MediaStream');


function MediaStreamRenderer(element) {
	debug('new() | [element:"%s"]', element);

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	if (!(element instanceof HTMLElement)) {
		throw new Error('a valid HTMLElement is required');
	}

	// Public atributes.
	this.element = element;
	this.stream = undefined;

	// Private attributes.
	this.id = randomNumber();
	this.videoWidth = undefined;
	this.videoHeight = undefined;
	this.element_added_style_width = undefined;
	this.element_added_style_height = undefined;

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'new_MediaStreamRenderer', [this.id]);

	this.refresh(this);
}


MediaStreamRenderer.prototype.render = function (stream) {
	debug('render() [stream:%o]', stream);

	var self = this;

	if (!(stream instanceof MediaStream)) {
		throw new Error('render() requires a MediaStream instance as argument');
	}

	this.stream = stream;

	exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_render', [this.id, stream.id]);

	// Subscribe to 'update' event so we call native mediaStreamChangedrefresh() on it.
	stream.addEventListener('update', function () {
		if (self.stream !== stream) {
			return;
		}

		debug('MediaStream emits "update", calling native mediaStreamChanged()');

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_mediaStreamChanged', [self.id]);
	});

	if (stream.connected) {
		emitVideoEvents();
	// Otherwise subscribe to 'connected' event to emulate video elements events.
	} else {
		stream.addEventListener('connected', function () {
			if (self.stream !== stream) {
				return;
			}

			emitVideoEvents();
		});
	}

	function emitVideoEvents() {
		self.element.dispatchEvent(new Event('loadedmetadata'));
		self.element.dispatchEvent(new Event('loadeddata'));
		self.element.dispatchEvent(new Event('canplay'));
		self.element.dispatchEvent(new Event('canplaythrough'));
	}
};


MediaStreamRenderer.prototype.refresh = function () {
	debug('refresh()');

	/**
	 * First remove "width" and "height" from the inline style in the element if
	 * previously added by this function.
	 */

	if (this.element_added_style_width && this.element.style.width) {
		debug('refresh() | removing element style width previously added by this function');

		this.element.style.width = '';
		this.element_added_style_width = undefined;
	}
	if (this.element_added_style_height && this.element.style.height) {
		debug('refresh() | removing element style height previously added by this function');

		this.element.style.height = '';
		this.element_added_style_height = undefined;
	}

	var elementPositionAndSize = getElementPositionAndSize.call(this),
		computedStyle,
		videoRatio,
		elementRatio,
		elementLeft = elementPositionAndSize.left,
		elementTop = elementPositionAndSize.top,
		elementWidth = elementPositionAndSize.width,
		elementHeight = elementPositionAndSize.height,
		videoViewWidth = elementWidth,
		videoViewHeight = elementHeight,
		visible,
		opacity,
		zIndex,
		mirrored,
		objectFit,
		clip;

	computedStyle = window.getComputedStyle(this.element);

	// visible
	if (computedStyle.visibility === 'hidden') {
		visible = false;
	} else {
		visible = !!this.element.offsetHeight;  // Returns 0 if element or any parent is hidden.
	}

	// opacity
	opacity = parseFloat(computedStyle.opacity);

	// zIndex
	zIndex = parseFloat(computedStyle.zIndex) || parseFloat(this.element.style.zIndex) || 0;

	// mirrored (detect "-webkit-transform: scaleX(-1);" or equivalent)
	if (computedStyle.transform === 'matrix(-1, 0, 0, 1, 0, 0)' ||
		computedStyle['-webkit-transform'] === 'matrix(-1, 0, 0, 1, 0, 0)') {
		mirrored = true;
	} else {
		mirrored = false;
	}

	// objectFit ('contain' is set as default value)
	objectFit = computedStyle.objectFit || 'contain';

	// clip
	if (objectFit === 'none') {
		clip = false;
	} else {
		clip = true;
	}

	/**
	 * No video yet, so just update the UIView with the element settings.
	 */

	if (!this.videoWidth || !this.videoHeight) {
		debug('refresh() | no video track yet');

		nativeRefresh.call(this);
		return;
	}

	videoRatio = this.videoWidth / this.videoHeight;

	/**
	 * Element has no width and/or no height.
	 */

	if (!elementWidth && !elementHeight) {
		debug('refresh() | video element has 0 width and 0 height');

		if (!this.element.style.width) {
			elementWidth = this.videoWidth;
			this.element.style.width = elementWidth + 'px';
			this.element_added_style_width = this.element.style.width;
		} else {
			elementWidth = parseInt(this.element.style.width);
		}

		if (!this.element.style.height) {
			elementHeight = this.videoHeight;
			this.element.style.height = elementHeight + 'px';
			this.element_added_style_height = this.element.style.height;
		} else {
			elementHeight = parseInt(this.element.style.height);
		}
	} else if (!elementWidth) {
		debug('refresh() | video element has 0 width');

		if (!this.element.style.width) {
			elementWidth = elementHeight * videoRatio;
			this.element.style.width = elementWidth + 'px';
			this.element_added_style_width = this.element.style.width;
		} else {
			elementWidth = parseInt(this.element.style.width);
		}
	} else if (!elementHeight) {
		debug('refresh() | video element has 0 height');

		if (!this.element.style.height) {
			elementHeight = elementWidth / videoRatio;
			this.element.style.height = elementHeight + 'px';
			this.element_added_style_height = this.element.style.height;
		} else {
			elementHeight = parseInt(this.element.style.height);
		}
	}

	/**
	 * Set video view position and size.
	 */

	elementRatio = elementWidth / elementHeight;

	switch (objectFit) {
		case 'cover':
			// The element has higher or equal width/height ratio than the video.
			if (elementRatio >= videoRatio) {
				videoViewWidth = elementWidth;
				videoViewHeight = videoViewWidth / videoRatio;
			// The element has lower width/height ratio than the video.
			} else if (elementRatio < videoRatio) {
				videoViewHeight = elementHeight;
				videoViewWidth = videoViewHeight * videoRatio;
			}
			break;

		case 'fill':
			videoViewHeight = elementHeight;
			videoViewWidth = elementWidth;
			break;

		case 'none':
			videoViewHeight = this.videoHeight;
			videoViewWidth = this.videoWidth;
			break;

		case 'scale-down':
			// Same as 'none'.
			if (this.videoWidth <= elementWidth && this.videoHeight <= elementHeight) {
				videoViewHeight = this.videoHeight;
				videoViewWidth = this.videoWidth;
			// Same as 'contain'.
			} else {
				// The element has higher or equal width/height ratio than the video.
				if (elementRatio >= videoRatio) {
					videoViewHeight = elementHeight;
					videoViewWidth = videoViewHeight * videoRatio;
				// The element has lower width/height ratio than the video.
				} else if (elementRatio < videoRatio) {
					videoViewWidth = elementWidth;
					videoViewHeight = videoViewWidth / videoRatio;
				}
			}
			break;

		// 'contain'.
		default:
			objectFit = 'contain';
			// The element has higher or equal width/height ratio than the video.
			if (elementRatio >= videoRatio) {
				videoViewHeight = elementHeight;
				videoViewWidth = videoViewHeight * videoRatio;
			// The element has lower width/height ratio than the video.
			} else if (elementRatio < videoRatio) {
				videoViewWidth = elementWidth;
				videoViewHeight = videoViewWidth / videoRatio;
			}
			break;
	}

	nativeRefresh.call(this);

	function nativeRefresh() {
		debug('refresh() | [elementLeft:%s, elementTop:%s, elementWidth:%s, elementHeight:%s, videoViewWidth:%s, videoViewHeight:%s, visible:%s, opacity:%s, zIndex:%s, mirrored:%s, objectFit:%s, clip:%s]',
			elementLeft, elementTop, elementWidth, elementHeight, videoViewWidth, videoViewHeight, visible, opacity, zIndex, mirrored, objectFit, clip);

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_refresh', [
			this.id, elementLeft, elementTop, elementWidth, elementHeight, videoViewWidth, videoViewHeight, visible, opacity, zIndex, mirrored, clip
		]);
	}
};


MediaStreamRenderer.prototype.close = function () {
	debug('close()');

	this.stream = undefined;

	exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_close', [this.id]);
};


/**
 * Private API.
 */


function onEvent(data) {
	var type = data.type,
		event;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'videoresize':
			this.videoWidth = data.size.width;
			this.videoHeight = data.size.height;
			this.refresh(this);

			event = new Event(type);
			event.videoWidth = data.size.width;
			event.videoHeight = data.size.height;
			this.dispatchEvent(event);

			break;
	}
}


function getElementPositionAndSize() {
	var rect = this.element.getBoundingClientRect();

	return {
		left:   rect.left + this.element.clientLeft,
		top:    rect.top + this.element.clientTop,
		width:  this.element.clientWidth,
		height: this.element.clientHeight
	};
}
