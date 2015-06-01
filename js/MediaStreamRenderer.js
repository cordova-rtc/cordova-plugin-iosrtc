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

	// Set black background.
	this.element.style.backgroundColor = '#000';

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
	this.stream.addEventListener('update', function () {
		debug('MediaStream emits "update", calling native mediaStreamChanged()');

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_mediaStreamChanged', [self.id]);
	});
};


MediaStreamRenderer.prototype.refresh = function () {
	debug('refresh()');

	/**
	 * First remove "width" and "height" from the inline style in the element (prebiously added
	 * by this method).
	 */

	var elementPositionAndSize = getElementPositionAndSize.call(this),
		videoRatio,
		elementRatio,
		elementLeft = elementPositionAndSize.left,
		elementTop = elementPositionAndSize.top,
		elementWidth = elementPositionAndSize.width,
		elementHeight = elementPositionAndSize.height,
		videoViewLeft = elementLeft,
		videoViewTop = elementTop,
		videoViewWidth = elementWidth,
		videoViewHeight = elementHeight,
		visible,
		opacity,
		zIndex;

	// visible
	if (window.getComputedStyle(this.element).visibility === 'hidden') {
		visible = false;
	} else {
		visible = !!this.element.offsetHeight;  // Returns 0 if element or any parent is hidden.
	}

	// opacity
	opacity = parseFloat(window.getComputedStyle(this.element).opacity);

	// zIndex
	zIndex = parseFloat(window.getComputedStyle(this.element).zIndex) || parseFloat(this.element.style.zIndex) || 0;

	/**
	 * No video yet, so just update the UIView with the element settings.
	 */

	if (!this.videoWidth || !this.videoHeight) {
		nativeRefresh.call(this);
		return;
	}

	videoRatio = this.videoWidth / this.videoHeight;

	/**
	 * Element has no width and/or no height.
	 */

	if (!elementWidth && !elementHeight) {
		debug('refresh() | no element width nor height');

		elementWidth = this.videoWidth;
		this.element.style.width = elementWidth + 'px';

		elementHeight = this.videoHeight;
		this.element.style.height = elementHeight + 'px';
	} else if (!elementWidth) {
		debug('refresh() | no element width');

		elementWidth = elementHeight * videoRatio;
		this.element.style.width = elementWidth + 'px';
	} else if (!elementHeight) {
		debug('refresh() | no element height');

		elementHeight = elementWidth / videoRatio;
		this.element.style.height = elementHeight + 'px';
	}

	/**
	 * Set video view position and size.
	 */

	elementRatio = elementWidth / elementHeight;

	debug('refresh() | [videoWidth:%s, videoHeight:%s, videoRatio:%s, elementRatio:%s]',
		this.videoWidth, this.videoHeight, videoRatio, elementRatio);

	// The element has higher or equal width/height ratio than the video.
	if (elementRatio >= videoRatio) {
		debug('refresh() | elementRatio:%s >= videoRatio:%s', elementRatio, videoRatio);

		videoViewHeight = elementHeight;
		videoViewWidth = videoViewHeight * videoRatio;
		videoViewLeft = elementLeft + ((elementWidth - videoViewWidth) / 2);
	// The element has lower width/height ratio than the video.
	} else if (elementRatio < videoRatio) {
		debug('refresh() | elementRatio:%s < videoRatio:%s', elementRatio, videoRatio);

		videoViewWidth = elementWidth;
		videoViewHeight = videoViewWidth / videoRatio;
		videoViewTop = elementTop + ((elementHeight - videoViewHeight) / 2);
	}

	nativeRefresh.call(this);

	function nativeRefresh() {
		debug('refresh() | videoView: [left:%s, top:%s, width:%s, height:%s, visible:%s, opacity:%s, zIndex:%s]',
			videoViewLeft, videoViewTop, videoViewWidth, videoViewHeight, visible, opacity, zIndex);

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_refresh', [
			this.id, videoViewLeft, videoViewTop, videoViewWidth, videoViewHeight, visible, opacity, zIndex
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
