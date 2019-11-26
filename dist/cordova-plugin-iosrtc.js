/*
 * cordova-plugin-iosrtc v6.0.4
 * Cordova iOS plugin exposing the full WebRTC W3C JavaScript APIs
 * Copyright 2015-2017 eFace2Face, Inc. (https://eface2face.com)
 * Copyright 2015-2019 BasqueVoIPMafia (https://github.com/BasqueVoIPMafia)
 * Copyright 2017-2019 Cordova-RTC (https://github.com/cordova-rtc)
 * License MIT
 */

(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.iosrtc = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(_dereq_,module,exports){
/**
 * Expose an object with WebRTC Errors.
 */
var Errors = module.exports = {},


/**
 * Local variables.
 */
	IntermediateInheritor = function () {};


IntermediateInheritor.prototype = Error.prototype;


/**
 * Create error classes.
 */
addError('InvalidStateError');
addError('InvalidSessionDescriptionError');
addError('InternalError');
addError('MediaStreamError');


function addError(name) {
	Errors[name] = function () {
		var tmp = Error.apply(this, arguments);

		this.name = tmp.name = name;
		this.message = tmp.message;

		Object.defineProperty(this, 'stack', {
			get: function () {
				return tmp.stack;
			}
		});

		return this;
	};

	Errors[name].prototype = new IntermediateInheritor();
}

// Detect callback usage to assist 5.0.1 to 5.0.2 migration
// TODO remove on 6.0.0
Errors.detectDeprecatedCallbaksUsage = function detectDeprecatedCallbaksUsage(funcName, arg) {
	if (
		typeof arg[1] === 'function' ||
			typeof arg[2] === 'function'
	) {
		throw new Error('Callbacks are not supported by "' + funcName + '" anymore, use Promise instead.');
	}
};
},{}],2:[function(_dereq_,module,exports){
/**
 * Dependencies.
 */
var
	YaetiEventTarget = _dereq_('yaeti').EventTarget;

var EventTarget = function () {
	YaetiEventTarget.call(this);
};

EventTarget.prototype = Object.create(YaetiEventTarget.prototype);
EventTarget.prototype.constructor = EventTarget;

/**
 * Expose the EventTarget class.
 */
module.exports = EventTarget;
},{"yaeti":24}],3:[function(_dereq_,module,exports){
/**
 * Expose the MediaDeviceInfo class.
 */
module.exports = MediaDeviceInfo;

function MediaDeviceInfo(data) {
	data = data || {};

	Object.defineProperties(this, {
		// MediaDeviceInfo spec.
		deviceId: {
			value: data.deviceId
		},
		kind: {
			value: data.kind
		},
		label: {
			value: data.label
		},
		groupId: {
			value: data.groupId || ''
		},
		// SourceInfo old spec.
		id: {
			value: data.deviceId
		},
		// Deprecated, but useful until there is an alternative
		facing: {
			value: ''
		}
	});
}

},{}],4:[function(_dereq_,module,exports){
/**
 * Expose the MediaStream class.
 */
module.exports = MediaStream;

/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastream
 */

/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:MediaStream'),
	exec = _dereq_('cordova/exec'),
	EventTarget = _dereq_('./EventTarget'),
	MediaStreamTrack = _dereq_('./MediaStreamTrack'),

/**
 * Local variables.
 */

	// Dictionary of MediaStreams (provided via getMediaStreams() class method).
	// - key: MediaStream blobId.
	// - value: MediaStream.
	mediaStreams;

// TODO longer UUID like native call
// - "4021904575-2849079001-3048689102-1644344044-4021904575-2849079001-3048689102-1644344044"
function newMediaStreamId() {
   return window.crypto.getRandomValues(new Uint32Array(4)).join('-');
}

// Save original MediaStream
var originalMediaStream = window.MediaStream;
var originalMediaStreamTrack = MediaStreamTrack.originalMediaStreamTrack;

/**
 * Expose the MediaStream class.
 */
function MediaStream(arg, id) {
	debug('new MediaStream(arg) | [arg:%o]', arg);

	// Detect native MediaStream usage
	// new MediaStream(originalMediaStream) // stream
	// new MediaStream(originalMediaStreamTrack[]) // tracks
	if (
		(arg instanceof originalMediaStream && typeof arg.getBlobId === 'undefined') ||
			(Array.isArray(arg) && arg[0] instanceof originalMediaStreamTrack)
	) {
		return new originalMediaStream(arg);
	}

	// new MediaStream(MediaStream) // stream
	// new MediaStream(MediaStreamTrack[]) // tracks
	// new MediaStream() // empty

	// TODO attempt CustomMediaStream extend.
	// Extend returned MediaTream with custom MediaStream
	var stream = new (Function.prototype.bind.apply(originalMediaStream.bind(this), [])); // jshint ignore:line
	Object.defineProperties(stream, Object.getOwnPropertyDescriptors(MediaStream.prototype));

	// Make it an EventTarget.
	EventTarget.call(stream);

	// Public atributes.
	stream._id = id || newMediaStreamId();
	stream._active = true;

	// Init Stream by Id
	exec(null, null, 'iosrtcPlugin', 'MediaStream_init', [stream.id]);

	// Public but internal attributes.
	stream.connected = false;

	// Private attributes.
	stream._audioTracks = {};
	stream._videoTracks = {};

	// Store the stream into the dictionary.
	stream._blobId = 'MediaStream_' + stream.id;
	mediaStreams[stream._blobId] = stream;

	// Convert arg to array of tracks if possible
	if (
		(arg instanceof MediaStream) ||
			(arg instanceof MediaStream.originalMediaStream)
	) {
		arg = arg.getTracks();
	}

	if (Array.isArray(arg)) {
		arg.forEach(function (track) {
			stream.addTrack(track);
		});
	} else if (typeof arg !== 'undefined') {
		throw new TypeError("Failed to construct 'MediaStream': No matching constructor signature.");
	}

	function onResultOK(data) {
		onEvent.call(stream, data);
	}
	exec(onResultOK, null, 'iosrtcPlugin', 'MediaStream_setListener', [stream.id]);

	return stream;
}

MediaStream.prototype = Object.create(originalMediaStream.prototype, {
	id: {
		get: function () {
			return this._id;
		}
	},
	active: {
		get: function () {
			return this._active;
		}
	},
	// Backwards compatibility.
	label: {
		get: function () {
			return this._id;
		}
	}
});

Object.defineProperties(MediaStream.prototype, Object.getOwnPropertyDescriptors(EventTarget.prototype));

MediaStream.prototype.constructor = MediaStream;

// Static reference to original MediaStream
MediaStream.originalMediaStream = originalMediaStream;

/**
 * Class methods.
 */

MediaStream.setMediaStreams = function (_mediaStreams) {
	mediaStreams = _mediaStreams;
};

MediaStream.getMediaStreams = function () {
	return mediaStreams;
};

MediaStream.create = function (dataFromEvent) {
	debug('create() | [dataFromEvent:%o]', dataFromEvent);

	var trackId, track,
		stream = new MediaStream([], dataFromEvent.id);

	// We do not use addTrack to prevent false positive "ERROR: video track not added" and "ERROR: audio track not added"
	// cause the rtcMediaStream already has them internaly.

	for (trackId in dataFromEvent.audioTracks) {
		if (dataFromEvent.audioTracks.hasOwnProperty(trackId)) {
			track = new MediaStreamTrack(dataFromEvent.audioTracks[trackId]);

			stream._audioTracks[track.id] = track;

			addListenerForTrackEnded.call(stream, track);
		}
	}

	for (trackId in dataFromEvent.videoTracks) {
		if (dataFromEvent.videoTracks.hasOwnProperty(trackId)) {
			track = new MediaStreamTrack(dataFromEvent.videoTracks[trackId]);

			stream._videoTracks[track.id] = track;

			addListenerForTrackEnded.call(stream, track);
		}
	}

	return stream;
};

MediaStream.prototype.getBlobId = function () {
	return this._blobId;
};

MediaStream.prototype.getAudioTracks = function () {
	debug('getAudioTracks()');

	var tracks = [],
		id;

	for (id in this._audioTracks) {
		if (this._audioTracks.hasOwnProperty(id)) {
			tracks.push(this._audioTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getVideoTracks = function () {
	debug('getVideoTracks()');

	var tracks = [],
		id;

	for (id in this._videoTracks) {
		if (this._videoTracks.hasOwnProperty(id)) {
			tracks.push(this._videoTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getTracks = function () {
	debug('getTracks()');

	var tracks = [],
		id;

	for (id in this._audioTracks) {
		if (this._audioTracks.hasOwnProperty(id)) {
			tracks.push(this._audioTracks[id]);
		}
	}

	for (id in this._videoTracks) {
		if (this._videoTracks.hasOwnProperty(id)) {
			tracks.push(this._videoTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getTrackById = function (id) {
	debug('getTrackById()');

	return this._audioTracks[id] || this._videoTracks[id] || null;
};


MediaStream.prototype.addTrack = function (track) {
	debug('addTrack() [track:%o]', track);

	if (!(track instanceof MediaStreamTrack)) {
		throw new Error('argument must be an instance of MediaStreamTrack');
	}

	if (this._audioTracks[track.id] || this._videoTracks[track.id]) {
		return;
	}

	if (track.kind === 'audio') {
		this._audioTracks[track.id] = track;
	} else if (track.kind === 'video') {
		this._videoTracks[track.id] = track;
	} else {
		throw new Error('unknown kind attribute: ' + track.kind);
	}

	addListenerForTrackEnded.call(this, track);

	exec(null, null, 'iosrtcPlugin', 'MediaStream_addTrack', [this.id, track.id]);
};


MediaStream.prototype.removeTrack = function (track) {
	debug('removeTrack() [track:%o]', track);

	if (!(track instanceof MediaStreamTrack)) {
		throw new Error('argument must be an instance of MediaStreamTrack');
	}

	if (!this._audioTracks[track.id] && !this._videoTracks[track.id]) {
		return;
	}

	if (track.kind === 'audio') {
		delete this._audioTracks[track.id];
	} else if (track.kind === 'video') {
		delete this._videoTracks[track.id];
	} else {
		throw new Error('unknown kind attribute: ' + track.kind);
	}

	exec(null, null, 'iosrtcPlugin', 'MediaStream_removeTrack', [this.id, track.id]);

	checkActive.call(this);
};


MediaStream.prototype.clone = function () {
	debug('clone()');
	return new MediaStream(this);
};

// Backwards compatible API.
MediaStream.prototype.stop = function () {
	debug('stop()');

	var trackId;

	for (trackId in this._audioTracks) {
		if (this._audioTracks.hasOwnProperty(trackId)) {
			this._audioTracks[trackId].stop();
		}
	}

	for (trackId in this._videoTracks) {
		if (this._videoTracks.hasOwnProperty(trackId)) {
			this._videoTracks[trackId].stop();
		}
	}
};


// TODO: API methods and events.


/**
 * Private API.
 */


MediaStream.prototype.emitConnected = function () {
	debug('emitConnected()');

	var self = this;

	if (this.connected) {
		return;
	}
	this.connected = true;

	setTimeout(function (self) {
		var event = new Event('connected');
		Object.defineProperty(event, 'target', {value: self, enumerable: true});
		self.dispatchEvent(event);
	}, 0, self);
};


function addListenerForTrackEnded(track) {
	var self = this;

	track.addEventListener('ended', function () {
		if (track.kind === 'audio' && !self._audioTracks[track.id]) {
			return;
		} else if (track.kind === 'video' && !self._videoTracks[track.id]) {
			return;
		}

		checkActive.call(self);
	});
}


function checkActive() {
	// A MediaStream object is said to be active when it has at least one MediaStreamTrack
	// that has not ended. A MediaStream that does not have any tracks or only has tracks
	// that are ended is inactive.

	var self = this,
		trackId;

	if (!this.active) {
		return;
	}

	if (Object.keys(this._audioTracks).length === 0 && Object.keys(this._videoTracks).length === 0) {
		debug('no tracks, releasing MediaStream');

		release();
		return;
	}

	for (trackId in this._audioTracks) {
		if (this._audioTracks.hasOwnProperty(trackId)) {
			if (this._audioTracks[trackId].readyState !== 'ended') {
				return;
			}
		}
	}

	for (trackId in this._videoTracks) {
		if (this._videoTracks.hasOwnProperty(trackId)) {
			if (this._videoTracks[trackId].readyState !== 'ended') {
				return;
			}
		}
	}

	debug('all tracks are ended, releasing MediaStream');
	release();

	function release() {
		self._active = false;
		self.dispatchEvent(new Event('inactive'));

		// Remove the stream from the dictionary.
		delete mediaStreams[self._blobId];

		exec(null, null, 'iosrtcPlugin', 'MediaStream_release', [self.id]);
	}
}


function onEvent(data) {
	var type = data.type,
		event,
		track;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'addtrack':
			track = new MediaStreamTrack(data.track);

			if (track.kind === 'audio') {
				this._audioTracks[track.id] = track;
			} else if (track.kind === 'video') {
				this._videoTracks[track.id] = track;
			}
			addListenerForTrackEnded.call(this, track);

			event = new Event('addtrack');
			event.track = track;

			this.dispatchEvent(event);

			// Also emit 'update' for the MediaStreamRenderer.
			this.dispatchEvent(new Event('update'));
			break;

		case 'removetrack':
			if (data.track.kind === 'audio') {
				track = this._audioTracks[data.track.id];
				delete this._audioTracks[data.track.id];
			} else if (data.track.kind === 'video') {
				track = this._videoTracks[data.track.id];
				delete this._videoTracks[data.track.id];
			}

			if (!track) {
				throw new Error('"removetrack" event fired on MediaStream for a non existing MediaStreamTrack');
			}

			event = new Event('removetrack');
			event.track = track;

			this.dispatchEvent(event);
			// Also emit 'update' for the MediaStreamRenderer.
			this.dispatchEvent(new Event('update'));

			// Check whether the MediaStream still is active.
			checkActive.call(this);
			break;
	}
}

},{"./EventTarget":2,"./MediaStreamTrack":6,"cordova/exec":undefined,"debug":18}],5:[function(_dereq_,module,exports){
/**
 * Expose the MediaStreamRenderer class.
 */
module.exports = MediaStreamRenderer;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:MediaStreamRenderer'),
	exec = _dereq_('cordova/exec'),
	randomNumber = _dereq_('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = _dereq_('./EventTarget'),
	MediaStream = _dereq_('./MediaStream');


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
	this.videoWidth = undefined;
	this.videoHeight = undefined;

	// Private attributes.
	this.id = randomNumber();

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'new_MediaStreamRenderer', [this.id]);

	this.refresh();

	// TODO cause video resizing jiggling add semaphore
	//this.refreshInterval = setInterval(function () {
	//	self.refresh(self);
	//}, 500);

	element.render = this;
}

MediaStreamRenderer.prototype = Object.create(EventTarget.prototype);
MediaStreamRenderer.prototype.constructor = MediaStreamRenderer;

MediaStreamRenderer.prototype.render = function (stream) {
	debug('render() [stream:%o]', stream);

	var self = this;

	if (!(stream instanceof MediaStream.originalMediaStream)) {
		throw new Error('render() requires a MediaStream instance as argument');
	}

	this.stream = stream;

	exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_render', [this.id, stream.id]);

	// Subscribe to 'update' event so we call native mediaStreamChanged() on it.
	stream.addEventListener('update', function () {
		if (self.stream !== stream) {
			return;
		}

		debug('MediaStream emits "update", calling native mediaStreamChanged()');

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_mediaStreamChanged', [self.id]);
	});

	// Subscribe to 'inactive' event and emit "close" so the video element can react.
	stream.addEventListener('inactive', function () {
		if (self.stream !== stream) {
			return;
		}

		debug('MediaStream emits "inactive", emiting "close" and closing this MediaStreamRenderer');

		self.dispatchEvent(new Event('close'));
		self.close();
	});

	if (stream.connected) {
		connected();
	// Otherwise subscribe to 'connected' event to emulate video elements events.
	} else {
		stream.addEventListener('connected', function () {
			if (self.stream !== stream) {
				return;
			}

			connected();
		});
	}

	function connected() {
		// Emit video events.
		self.element.dispatchEvent(new Event('loadedmetadata'));
		self.element.dispatchEvent(new Event('loadeddata'));
		self.element.dispatchEvent(new Event('canplay'));
		self.element.dispatchEvent(new Event('canplaythrough'));
	}
};

MediaStreamRenderer.prototype.save = function (callback) {
	debug('save()');

	if (!this.stream) {
		callback(null);
		return;
	}

	function onResultOK(data) {
		callback(data);
	}

	function onResultError() {
		callback(null);
	}

	exec(onResultOK, onResultError, 'iosrtcPlugin', 'MediaStreamRenderer_save', [this.id]);
};

MediaStreamRenderer.prototype.refresh = function () {
	debug('refresh()');

	var elementPositionAndSize = getElementPositionAndSize.call(this),
		computedStyle,
		videoRatio,
		elementRatio,
		elementLeft = elementPositionAndSize.left,
		elementTop = elementPositionAndSize.top,
		elementWidth = elementPositionAndSize.width,
		elementHeight = elementPositionAndSize.height,
		videoViewWidth,
		videoViewHeight,
		visible,
		opacity,
		zIndex,
		mirrored,
		objectFit,
		clip,
		borderRadius,
		paddingTop,
		paddingBottom,
		paddingLeft,
		paddingRight,
		self = this;

	computedStyle = window.getComputedStyle(this.element);

	// get padding values
	paddingTop = parseInt(computedStyle.paddingTop) | 0;
	paddingBottom = parseInt(computedStyle.paddingBottom) | 0;
	paddingLeft = parseInt(computedStyle.paddingLeft) | 0;
	paddingRight = parseInt(computedStyle.paddingRight) | 0;

	// fix position according to padding
	elementLeft += paddingLeft;
	elementTop += paddingTop;

	// fix width and height according to padding
	elementWidth -= (paddingLeft + paddingRight);
	elementHeight -= (paddingTop + paddingBottom);

	videoViewWidth = elementWidth;
	videoViewHeight = elementHeight;

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

	// borderRadius
	borderRadius = parseFloat(computedStyle.borderRadius);
	if (/%$/.test(borderRadius)) {
		borderRadius = Math.min(elementHeight, elementWidth) * borderRadius;
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

	if (!elementWidth || !elementHeight) {
		debug('refresh() | video element has 0 width and/or 0 height');

		nativeRefresh.call(this);
		return;
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

	function hash(str) {
		var hash = 5381,
		i = str.length;

		while (i) {
			hash = (hash * 33) ^ str.charCodeAt(--i);
		}

		return hash >>> 0;
	}

	function nativeRefresh() {
		var data = {
			elementLeft: Math.round(elementLeft),
			elementTop: Math.round(elementTop),
			elementWidth: Math.round(elementWidth),
			elementHeight: Math.round(elementHeight),
			videoViewWidth: Math.round(videoViewWidth),
			videoViewHeight: Math.round(videoViewHeight),
			visible: visible,
			opacity: opacity,
			zIndex: zIndex,
			mirrored: mirrored,
			objectFit: objectFit,
			clip: clip,
			borderRadius: borderRadius
		},
		newRefreshCached = hash(JSON.stringify(data));

		if (newRefreshCached === self.refreshCached) {
			return;
		}

		self.refreshCached = newRefreshCached;

		debug('refresh() | [data:%o]', data);

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_refresh', [this.id, data]);
	}
};


MediaStreamRenderer.prototype.close = function () {
	debug('close()');

	if (!this.stream) {
		return;
	}
	this.stream = undefined;

	exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_close', [this.id]);
	if (this.refreshInterval) {
		clearInterval(this.refreshInterval);
		delete this.refreshInterval;
	}
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
			this.refresh();

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

},{"./EventTarget":2,"./MediaStream":4,"cordova/exec":undefined,"debug":18,"random-number":23}],6:[function(_dereq_,module,exports){
/**
 * Expose the MediaStreamTrack class.
 */
module.exports = MediaStreamTrack;


/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastreamtrack
 */


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:MediaStreamTrack'),
	exec = _dereq_('cordova/exec'),
	enumerateDevices = _dereq_('./enumerateDevices'),
	EventTarget = _dereq_('./EventTarget');

// Save original MediaStreamTrack
var originalMediaStreamTrack = window.MediaStreamTrack;

function MediaStreamTrack(dataFromEvent) {
	debug('new() | [dataFromEvent:%o]', dataFromEvent);

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Public atributes.
	this.id = dataFromEvent.id;  // NOTE: It's a string.
	this.kind = dataFromEvent.kind;
	this.label = dataFromEvent.label;
	this.muted = false;  // TODO: No "muted" property in ObjC API.
	this.readyState = dataFromEvent.readyState;

	// Private attributes.
	this._enabled = dataFromEvent.enabled;
	this._ended = false;

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'MediaStreamTrack_setListener', [this.id]);
}

MediaStreamTrack.prototype = Object.create(EventTarget.prototype);
MediaStreamTrack.prototype.constructor = MediaStreamTrack;

// Static reference to original MediaStreamTrack
MediaStreamTrack.originalMediaStreamTrack = originalMediaStreamTrack;

// Setters.
Object.defineProperty(MediaStreamTrack.prototype, 'enabled', {
	get: function () {
		return this._enabled;
	},
	set: function (value) {
		debug('enabled = %s', !!value);

		this._enabled = !!value;
		exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_setEnabled', [this.id, this._enabled]);
	}
});


MediaStreamTrack.prototype.stop = function () {
	debug('stop()');

	if (this._ended) {
		return;
	}

	exec(null, null, 'iosrtcPlugin', 'MediaStreamTrack_stop', [this.id]);
};


// TODO: API methods and events.


/**
 * Class methods.
 */


MediaStreamTrack.getSources = function () {
	debug('getSources()');

	return enumerateDevices.apply(this, arguments);
};


/**
 * Private API.
 */


function onEvent(data) {
	var type = data.type;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'statechange':
			this.readyState = data.readyState;
			this._enabled = data.enabled;

			switch (data.readyState) {
				case 'initializing':
					break;
				case 'live':
					break;
				case 'ended':
					this._ended = true;
					this.dispatchEvent(new Event('ended'));
					break;
				case 'failed':
					break;
			}
			break;
	}
}

},{"./EventTarget":2,"./enumerateDevices":14,"cordova/exec":undefined,"debug":18}],7:[function(_dereq_,module,exports){
/**
 * Expose the RTCDTMFSender class.
 */
module.exports = RTCDTMFSender;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:RTCDTMFSender'),
	debugerror = _dereq_('debug')('iosrtc:ERROR:RTCDTMFSender'),
	exec = _dereq_('cordova/exec'),
	randomNumber = _dereq_('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = _dereq_('./EventTarget');


debugerror.log = console.warn.bind(console);


function RTCDTMFSender(peerConnection, track) {
	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	debug('new() | [track:%o]', track);

	// Public atributes (accessed as read-only properties)
	this._track = track;
	// TODO: read these from the properties exposed in Swift?
	this._duration = 100;
	this._interToneGap = 70;
	this._toneBuffer = '';

	// Private attributes.
	this.peerConnection = peerConnection;
	this.dsId = randomNumber();

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDTMFSender', [this.peerConnection.pcId, this.dsId, this._track.id]);

}

RTCDTMFSender.prototype = Object.create(EventTarget.prototype);
RTCDTMFSender.prototype.constructor = RTCDTMFSender;

Object.defineProperty(RTCDTMFSender.prototype, 'canInsertDTMF', {
	get: function () {
		// TODO: check if it's muted or stopped?
		return this._track && this._track.kind === 'audio' && this._track.enabled;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'track', {
	get: function () {
		return this._track;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'duration', {
	get: function () {
		return this._duration;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'interToneGap', {
	get: function () {
		return this._interToneGap;
	}
});


Object.defineProperty(RTCDTMFSender.prototype, 'toneBuffer', {
	get: function () {
		return this._toneBuffer;
	}
});


RTCDTMFSender.prototype.insertDTMF = function (tones, duration, interToneGap) {
	if (isClosed.call(this)) {
		return;
	}

	debug('insertDTMF() | [tones:%o, duration:%o, interToneGap:%o]', tones, duration, interToneGap);

	if (!tones) {
		return;
	}

	this._duration = duration || 100;
	this._interToneGap = interToneGap || 70;

	var self = this;

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDTMFSender_insertDTMF', [this.peerConnection.pcId, this.dsId, tones, this._duration, this._interToneGap]);
};


/**
 * Private API.
 */


function isClosed() {
	return this.peerConnection.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		event;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	if (type === 'tonechange') {
		event = new Event('tonechange');
		event.tone = data.tone;
		this.dispatchEvent(event);
	}
}

},{"./EventTarget":2,"cordova/exec":undefined,"debug":18,"random-number":23}],8:[function(_dereq_,module,exports){
/**
 * Expose the RTCDataChannel class.
 */
module.exports = RTCDataChannel;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:RTCDataChannel'),
	debugerror = _dereq_('debug')('iosrtc:ERROR:RTCDataChannel'),
	exec = _dereq_('cordova/exec'),
	randomNumber = _dereq_('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = _dereq_('./EventTarget');


debugerror.log = console.warn.bind(console);


function RTCDataChannel(peerConnection, label, options, dataFromEvent) {
	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Created via pc.createDataChannel().
	if (!dataFromEvent) {
		debug('new() | [label:%o, options:%o]', label, options);

		if (typeof label !== 'string') {
			label = '';
		}

		options = options || {};

		if (options.hasOwnProperty('maxPacketLifeTime') && options.hasOwnProperty('maxRetransmits')) {
			throw new SyntaxError('both maxPacketLifeTime and maxRetransmits can not be present');
		}

		if (options.hasOwnProperty('id')) {
			if (typeof options.id !== 'number' || isNaN(options.id) || options.id < 0) {
				throw new SyntaxError('id must be a number');
			}
			// TODO:
			//   https://code.google.com/p/webrtc/issues/detail?id=4618
			if (options.id > 1023) {
				throw new SyntaxError('id cannot be greater than 1023 (https://code.google.com/p/webrtc/issues/detail?id=4614)');
			}
		}

		// Public atributes.
		this.label = label;
		this.ordered = options.hasOwnProperty('ordered') ? !!options.ordered : true;
		this.maxPacketLifeTime = options.hasOwnProperty('maxPacketLifeTime') ? Number(options.maxPacketLifeTime) : null;
		this.maxRetransmits = options.hasOwnProperty('maxRetransmits') ? Number(options.maxRetransmits) : null;
		this.protocol = options.hasOwnProperty('protocol') ? String(options.protocol) : '';
		this.negotiated = options.hasOwnProperty('negotiated') ? !!options.negotiated : false;
		this.id = options.hasOwnProperty('id') ? Number(options.id) : undefined;
		this.readyState = 'connecting';
		this.bufferedAmount = 0;
		this.bufferedAmountLowThreshold = 0;

		// Private attributes.
		this.peerConnection = peerConnection;
		this.dcId = randomNumber();

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDataChannel', [this.peerConnection.pcId, this.dcId, label, options]);
	// Created via pc.ondatachannel.
	} else {
		debug('new() | [dataFromEvent:%o]', dataFromEvent);

		// Public atributes.
		this.label = dataFromEvent.label;
		this.ordered = dataFromEvent.ordered;
		this.maxPacketLifeTime = dataFromEvent.maxPacketLifeTime;
		this.maxRetransmits = dataFromEvent.maxRetransmits;
		this.protocol = dataFromEvent.protocol;
		this.negotiated = dataFromEvent.negotiated;
		this.id = dataFromEvent.id;
		this.readyState = dataFromEvent.readyState;
		this.bufferedAmount = dataFromEvent.bufferedAmount;
		this.bufferedAmountLowThreshold = dataFromEvent.bufferedAmountLowThreshold;

		// Private attributes.
		this.peerConnection = peerConnection;
		this.dcId = dataFromEvent.dcId;

		exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_setListener', [this.peerConnection.pcId, this.dcId]);
	}

	function onResultOK(data) {
		if (data.type) {
			onEvent.call(self, data);
		// Special handler for received binary mesage.
		} else {
			onEvent.call(self, {
				type: 'message',
				message: data
			});
		}
	}
}

RTCDataChannel.prototype = Object.create(EventTarget.prototype);
RTCDataChannel.prototype.constructor = RTCDataChannel;

// Just 'arraybuffer' binaryType is implemented in Chromium.
Object.defineProperty(RTCDataChannel.prototype, 'binaryType', {
	get: function () {
		return 'arraybuffer';
	},
	set: function (type) {
		if (type !== 'arraybuffer') {
			throw new Error('just "arraybuffer" is implemented for binaryType');
		}
	}
});


RTCDataChannel.prototype.send = function (data) {
	if (isClosed.call(this) || this.readyState !== 'open') {
		return;
	}

	debug('send() | [data:%o]', data);

	if (!data) {
		return;
	}

	if (typeof data === 'string' || data instanceof String) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendString', [this.peerConnection.pcId, this.dcId, data]);
	} else if (window.ArrayBuffer && data instanceof window.ArrayBuffer) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [this.peerConnection.pcId, this.dcId, data]);
	} else if (
		(window.Int8Array && data instanceof window.Int8Array) ||
		(window.Uint8Array && data instanceof window.Uint8Array) ||
		(window.Uint8ClampedArray && data instanceof window.Uint8ClampedArray) ||
		(window.Int16Array && data instanceof window.Int16Array) ||
		(window.Uint16Array && data instanceof window.Uint16Array) ||
		(window.Int32Array && data instanceof window.Int32Array) ||
		(window.Uint32Array && data instanceof window.Uint32Array) ||
		(window.Float32Array && data instanceof window.Float32Array) ||
		(window.Float64Array && data instanceof window.Float64Array) ||
		(window.DataView && data instanceof window.DataView)
	) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [this.peerConnection.pcId, this.dcId, data.buffer]);
	} else {
		throw new Error('invalid data type');
	}
};


RTCDataChannel.prototype.close = function () {
	if (isClosed.call(this)) {
		return;
	}

	debug('close()');

	this.readyState = 'closing';

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_close', [this.peerConnection.pcId, this.dcId]);
};


/**
 * Private API.
 */


function isClosed() {
	return this.readyState === 'closed' || this.readyState === 'closing' || this.peerConnection.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		event;

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'new':
			// Update properties and exit without firing the event.
			this.ordered = data.channel.ordered;
			this.maxPacketLifeTime = data.channel.maxPacketLifeTime;
			this.maxRetransmits = data.channel.maxRetransmits;
			this.protocol = data.channel.protocol;
			this.negotiated = data.channel.negotiated;
			this.id = data.channel.id;
			this.readyState = data.channel.readyState;
			this.bufferedAmount = data.channel.bufferedAmount;
			break;

		case 'statechange':
			this.readyState = data.readyState;

			switch (data.readyState) {
				case 'connecting':
					break;
				case 'open':
					this.dispatchEvent(new Event('open'));
					break;
				case 'closing':
					break;
				case 'closed':
					this.dispatchEvent(new Event('close'));
					break;
			}
			break;

		case 'message':
			event = new Event('message');
			event.data = data.message;
			this.dispatchEvent(event);
			break;

		case 'bufferedamount':
			this.bufferedAmount = data.bufferedAmount;

			if (this.bufferedAmountLowThreshold > 0 && this.bufferedAmountLowThreshold > this.bufferedAmount) {
				event = new Event('bufferedamountlow');
				event.bufferedAmount = this.bufferedAmount;
				this.dispatchEvent(event);
			}

			break;
	}
}

},{"./EventTarget":2,"cordova/exec":undefined,"debug":18,"random-number":23}],9:[function(_dereq_,module,exports){
/**
 * Expose the RTCIceCandidate class.
 */
module.exports = RTCIceCandidate;


function RTCIceCandidate(data) {
	data = data || {};

	// Public atributes.
	this.sdpMid = data.sdpMid;
	this.sdpMLineIndex = data.sdpMLineIndex;
	this.candidate = data.candidate;
}

},{}],10:[function(_dereq_,module,exports){
(function (global){
/**
 * Expose the RTCPeerConnection class.
 */
module.exports = RTCPeerConnection;


/**
 * Dependencies.
 */
var 
	debug = _dereq_('debug')('iosrtc:RTCPeerConnection'),
	debugerror = _dereq_('debug')('iosrtc:ERROR:RTCPeerConnection'),
	exec = _dereq_('cordova/exec'),
	randomNumber = _dereq_('random-number').generator({min: 10000, max: 99999, integer: true}),
	EventTarget = _dereq_('./EventTarget'),
	RTCSessionDescription = _dereq_('./RTCSessionDescription'),
	RTCIceCandidate = _dereq_('./RTCIceCandidate'),
	RTCDataChannel = _dereq_('./RTCDataChannel'),
	RTCDTMFSender = _dereq_('./RTCDTMFSender'),
	RTCStatsResponse = _dereq_('./RTCStatsResponse'),
	RTCStatsReport = _dereq_('./RTCStatsReport'),
	MediaStream = _dereq_('./MediaStream'),
	MediaStreamTrack = _dereq_('./MediaStreamTrack'),
	Errors = _dereq_('./Errors');

debugerror.log = console.warn.bind(console);

function deprecateWarning(method, newMethod) {
	if (!newMethod) {
		console.warn(method + ' is deprecated.');
	} else {
		console.warn(method + ' method is deprecated, use ' + newMethod + ' instead.');	
	}
}

function RTCPeerConnection(pcConfig, pcConstraints) {
	debug('new() | [pcConfig:%o, pcConstraints:%o]', pcConfig, pcConstraints);

	var self = this;

	// Make this an EventTarget.
	EventTarget.call(this);

	// Restore corrupted RTCPeerConnection.prototype
	// TODO find why webrtc-adapter prevent events onnegotiationneeded to be trigger.
	// Object.defineProperties(this, RTCPeerConnection.prototype_descriptor);

	// Fix webrtc-adapter bad SHIM on addTrack causing error when original does support multiple streams.
	// NotSupportedError: The adapter.js addTrack polyfill only supports a single stream which is associated with the specified track.
	Object.defineProperty(this, 'addTrack', RTCPeerConnection.prototype_descriptor.addTrack);
	Object.defineProperty(this, 'getLocalStreams', RTCPeerConnection.prototype_descriptor.getLocalStreams);
	
	// Public atributes.
	this._localDescription = null;
	this.remoteDescription = null;
	this.signalingState = 'stable';
	this.iceGatheringState = 'new';
	this.iceConnectionState = 'new';
	this.pcConfig = fixPcConfig(pcConfig);

	// Private attributes.
	this.pcId = randomNumber();
	this.localStreams = {};
	this.remoteStreams = {};

	function onResultOK(data) {
		onEvent.call(self, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'new_RTCPeerConnection', [this.pcId, this.pcConfig, pcConstraints]);
}

RTCPeerConnection.prototype = Object.create(EventTarget.prototype);
RTCPeerConnection.prototype.constructor = RTCPeerConnection;

Object.defineProperties(RTCPeerConnection.prototype, {
	'localDescription': { 
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		get: function() { 
			return this._localDescription;
		}
	},
	'connectionState': { 
		get: function() { 
			return this.iceConnectionState;
		} 
	},
	'onicecandidate': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('icecandidate', callback);
		}
	},
	'onaddstream': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('addstream', callback);
		}
	},
	'oniceconnectionstatechange': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('iceconnectionstatechange', callback);
		}
	},
	'onnegotiationneeded': {
		// Fix webrtc-adapter TypeError: Attempting to change the getter of an unconfigurable property.
		configurable: true,
		set: function (callback) {
			return this.addEventListener('negotiationneeded', callback);
		}
	}
});

RTCPeerConnection.prototype.createOffer = function (options) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createOffer', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return;
	}

	debug('createOffer() [options:%o]', options);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			var desc = new RTCSessionDescription(data);

			debug('createOffer() | success [desc:%o]', desc);
			resolve(desc);
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('createOffer() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createOffer', [self.pcId, options]);
	});
};


RTCPeerConnection.prototype.createAnswer = function (options) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createAnswer', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return;
	}

	debug('createAnswer() [options:%o]', options);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			var desc = new RTCSessionDescription(data);

			debug('createAnswer() | success [desc:%o]', desc);
			resolve(desc);
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('createAnswer() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createAnswer', [self.pcId, options]);
	});
};

RTCPeerConnection.prototype.setLocalDescription = function (desc) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.setLocalDescription', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other 
	// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary, 
	// so you don't have to instantiate an RTCSessionDescription yourself.""
	// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
	// Still we do instnanciate RTCSessionDescription, so internal object is used properly.

	if (!(desc instanceof RTCSessionDescription)) {
		desc = new RTCSessionDescription(desc);
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('setLocalDescription() | success');
			// Update localDescription.
			self._localDescription = new RTCSessionDescription(data);
			resolve();
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('setLocalDescription() | failure: %s', error);
			reject(new Errors.InvalidSessionDescriptionError('setLocalDescription() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setLocalDescription', [self.pcId, desc]);
	});
};

RTCPeerConnection.prototype.setRemoteDescription = function (desc) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.setRemoteDescription', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	debug('setRemoteDescription() [desc:%o]', desc);

	// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other 
	// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary, 
	// so you don't have to instantiate an RTCSessionDescription yourself.""
	// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
	// Still we do instnanciate RTCSessionDescription so internal object is used properly.

	if (!(desc instanceof RTCSessionDescription)) {
		desc = new RTCSessionDescription(desc);
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('setRemoteDescription() | success');
			// Update remoteDescription.
			self.remoteDescription = new RTCSessionDescription(data);
			resolve();
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('setRemoteDescription() | failure: %s', error);
			reject(new Errors.InvalidSessionDescriptionError('setRemoteDescription() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_setRemoteDescription', [self.pcId, desc]);
	});
};

RTCPeerConnection.prototype.addIceCandidate = function (candidate) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.addIceCandidate', arguments);

	var self = this;

	if (isClosed.call(this)) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.InvalidStateError('peerconnection is closed'));
		});
	}

	debug('addIceCandidate() | [candidate:%o]', candidate);

	if (typeof candidate !== 'object') {
		return new Promise(function (resolve, reject) {
			reject(new global.DOMException('addIceCandidate() must be called with a RTCIceCandidate instance or RTCIceCandidateInit object as argument'));
		});
	}

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			if (isClosed.call(self)) {
				return;
			}

			debug('addIceCandidate() | success');
			// Update remoteDescription.
			if (self.remoteDescription && data.remoteDescription) {
				self.remoteDescription.type = data.remoteDescription.type;
				self.remoteDescription.sdp = data.remoteDescription.sdp;
			} else if (data.remoteDescription) {
				self.remoteDescription = new RTCSessionDescription(data.remoteDescription);
			}
			resolve();
		}

		function onResultError() {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('addIceCandidate() | failure');
			reject(new global.DOMException('addIceCandidate() failed'));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_addIceCandidate', [self.pcId, candidate]);
	});
};

RTCPeerConnection.prototype.getConfiguration = function () {
	debug('getConfiguration()');

	return this.pcConfig;
};

RTCPeerConnection.prototype.getLocalStreams = function () {
	debug('getLocalStreams()');
	deprecateWarning('getLocalStreams', 'getSenders');

	var streams = [],
		id;

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			streams.push(this.localStreams[id]);
		}
	}

	return streams;
};


RTCPeerConnection.prototype.getRemoteStreams = function () {
	debug('getRemoteStreams()');
	deprecateWarning('getRemoteStreams', 'getReceivers');

	var streams = [],
		id;

	for (id in this.remoteStreams) {
		if (this.remoteStreams.hasOwnProperty(id)) {
			streams.push(this.remoteStreams[id]);
		}
	}

	return streams;
};

RTCPeerConnection.prototype.getReceivers = function () {
	var tracks = [],
		id;

	for (id in this.remoteStreams) {
		if (this.remoteStreams.hasOwnProperty(id)) {
			tracks = tracks.concat(this.remoteStreams[id].getTracks());
		}
	}

	return tracks;
};

RTCPeerConnection.prototype.getSenders = function () {
	var tracks = [],
		id;

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			tracks = tracks.concat(this.localStreams[id].getTracks());
		}
	}

	return tracks;
};

RTCPeerConnection.prototype.addTrack = function (track, stream) {
	var id;

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	// Add localStreams if missing
	// Disable to match browser behavior
	//stream = stream || Object.values(this.localStreams)[0] || new MediaStream();

	// Fix webrtc-adapter bad SHIM on addStream
	if (stream) {
		if (!(stream instanceof MediaStream.originalMediaStream)) {
			throw new Error('addTrack() must be called with a MediaStream instance as argument');
		}

		if (!this.localStreams[stream.id]) {
			this.localStreams[stream.id] = stream;
		}

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
	}

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			// Target provided stream argument or first added stream to group track
			if (!stream || (stream && stream.id === id)) { 
				stream = this.localStreams[id];
				stream.addTrack(track);
				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [this.pcId, track.id, id]);
				break;
			}
		}
	}

	// No Stream matched add track without stream
	if (!stream) {
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [this.pcId, track.id, null]);
	}
};

RTCPeerConnection.prototype.removeTrack = function (track) {
	var id,
		stream,
		hasTrack;

	function matchLocalTrack(localTrack) {
		return localTrack.id === track.id;
	}

	for (id in this.localStreams) {
		if (this.localStreams.hasOwnProperty(id)) {
			// Check if track is belong to stream
			hasTrack = (this.localStreams[id].getTracks().filter(matchLocalTrack).length > 0);

			if (hasTrack) {
				stream = this.localStreams[id];
				stream.removeTrack(track);

				exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeTrack', [this.pcId, track.id, stream.id]);
				break;
			}
		}
	}
};

RTCPeerConnection.prototype.getStreamById = function (id) {
	debug('getStreamById()');

	return this.localStreams[id] || this.remoteStreams[id] || null;
};


RTCPeerConnection.prototype.addStream = function (stream) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('addStream()');

	if (!(stream instanceof MediaStream.originalMediaStream)) {
		throw new Error('addStream() must be called with a MediaStream instance as argument');
	}

	if (this.localStreams[stream.id]) {
		debugerror('addStream() | given stream already in present in local streams');
		return;
	}

	this.localStreams[stream.id] = stream;

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
};


RTCPeerConnection.prototype.removeStream = function (stream) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('removeStream()');

	if (!(stream instanceof MediaStream.originalMediaStream)) {
		throw new Error('removeStream() must be called with a MediaStream instance as argument');
	}

	if (!this.localStreams[stream.id]) {
		debugerror('removeStream() | given stream not present in local streams');
		return;
	}

	delete this.localStreams[stream.id];

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeStream', [this.pcId, stream.id]);
};


RTCPeerConnection.prototype.createDataChannel = function (label, options) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('createDataChannel() [label:%s, options:%o]', label, options);

	return new RTCDataChannel(this, label, options);
};


RTCPeerConnection.prototype.createDTMFSender = function (track) {
	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('createDTMFSender() [track:%o]', track);

	return new RTCDTMFSender(this, track);
};

RTCPeerConnection.prototype.getStats = function (selector) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.getStats', arguments);

	var self = this;

	if (selector && !(selector instanceof MediaStreamTrack)) {
		throw new Error('getStats() must be called with null or a valid MediaStreamTrack instance as argument');
	}

	if (isClosed.call(this)) {
		throw new Errors.InvalidStateError('peerconnection is closed');
	}

	debug('getStats() [selector:%o]', selector);

	return new Promise(function (resolve, reject) {
		function onResultOK(array) {
			if (isClosed.call(self)) {
				return;
			}

			var res = [];
			array.forEach(function (stat) {
				res.push(new RTCStatsReport(stat));
			});
			resolve(new RTCStatsResponse(res));
		}

		function onResultError(error) {
			if (isClosed.call(self)) {
				return;
			}

			debugerror('getStats() | failure: %s', error);
			reject(new global.DOMException(error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_getStats', [self.pcId, selector ? selector.id : null]);
	});
};

RTCPeerConnection.prototype.close = function () {
	if (isClosed.call(this)) {
		return;
	}

	debug('close()');

	exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_close', [this.pcId]);
};

// Save current RTCPeerConnection.prototype
RTCPeerConnection.prototype_descriptor = Object.getOwnPropertyDescriptors(RTCPeerConnection.prototype);

/**
 * Private API.
 */
function fixPcConfig(pcConfig) {
	if (!pcConfig) {
		return {
			iceServers: []
		};
	}

	var iceServers = pcConfig.iceServers,
		i, len, iceServer;

	if (!Array.isArray(iceServers)) {
		pcConfig.iceServers = [];
		return pcConfig;
	}

	for (i = 0, len = iceServers.length; i < len; i++) {
		iceServer = iceServers[i];

		// THe Objective-C wrapper of WebRTC is old and does not implement .urls.
		if (iceServer.url) {
			continue;
		} else if (Array.isArray(iceServer.urls)) {
			iceServer.url = iceServer.urls[0];
		} else if (typeof iceServer.urls === 'string') {
			iceServer.url = iceServer.urls;
		}
	}

	return pcConfig;
}


function isClosed() {
	return this.signalingState === 'closed';
}


function onEvent(data) {
	var type = data.type,
		self = this,
		event = new Event(type),
		stream,
		dataChannel,
		id;

	Object.defineProperty(event, 'target', {value: self, enumerable: true});

	debug('onEvent() | [type:%s, data:%o]', type, data);

	switch (type) {
		case 'signalingstatechange':
			this.signalingState = data.signalingState;
			break;

		case 'icegatheringstatechange':
			this.iceGatheringState = data.iceGatheringState;
			break;

		case 'iceconnectionstatechange':
			this.iceConnectionState = data.iceConnectionState;

			// Emit "connected" on remote streams if ICE connected.
			if (data.iceConnectionState === 'connected') {
				for (id in this.remoteStreams) {
					if (this.remoteStreams.hasOwnProperty(id)) {
						this.remoteStreams[id].emitConnected();
					}
				}
			}
			break;

		case 'icecandidate':
			if (data.candidate) {
				event.candidate = new RTCIceCandidate(data.candidate);
			} else {
				event.candidate = null;
			}
			// Update _localDescription.
			if (this._localDescription) {
				this._localDescription.type = data.localDescription.type;
				this._localDescription.sdp = data.localDescription.sdp;
			} else {
				this._localDescription = new RTCSessionDescription(data);
			}
			break;

		case 'negotiationneeded':
			break;

		case 'addtrack':
			event.track = data.track;
			break;

		case 'addstream':
			stream = MediaStream.create(data.stream);
			event.stream = stream;

			// Append to the remote streams.
			this.remoteStreams[stream.id] = stream;

			// Emit "connected" on the stream if ICE connected.
			if (this.iceConnectionState === 'connected' || this.iceConnectionState === 'completed') {
				stream.emitConnected();
			}
			break;

		case 'removestream':
			stream = this.remoteStreams[data.streamId];
			event.stream = stream;

			// Remove from the remote streams.
			delete this.remoteStreams[stream.id];
			break;

		case 'datachannel':
			dataChannel = new RTCDataChannel(this, null, null, data.channel);
			event.channel = dataChannel;
			break;
	}

	this.dispatchEvent(event);
}

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./Errors":1,"./EventTarget":2,"./MediaStream":4,"./MediaStreamTrack":6,"./RTCDTMFSender":7,"./RTCDataChannel":8,"./RTCIceCandidate":9,"./RTCSessionDescription":11,"./RTCStatsReport":12,"./RTCStatsResponse":13,"cordova/exec":undefined,"debug":18,"random-number":23}],11:[function(_dereq_,module,exports){
/**
 * Expose the RTCSessionDescription class.
 */
module.exports = RTCSessionDescription;


function RTCSessionDescription(data) {
	data = data || {};

	// Public atributes.
	this.type = data.type;
	this.sdp = data.sdp;
}

},{}],12:[function(_dereq_,module,exports){
/**
 * Expose the RTCStatsReport class.
 */
module.exports = RTCStatsReport;

function RTCStatsReport(data) {
	data = data || [];

	this.id = data.reportId;
	this.timestamp = data.timestamp;
	this.type = data.type;

	this.names = function () {
		return Object.keys(data.values);
	};

	this.stat = function (key) {
		return data.values[key] || '';
	};
}

},{}],13:[function(_dereq_,module,exports){
/**
 * Expose the RTCStatsResponse class.
 */
module.exports = RTCStatsResponse;

function RTCStatsResponse(data) {
	data = data || [];

	this.result = function () {
		return data;
	};

	this.namedItem = function () {
		return null;
	};
}

},{}],14:[function(_dereq_,module,exports){
/**
 * Expose the enumerateDevices function.
 */
module.exports = enumerateDevices;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:enumerateDevices'),
	exec = _dereq_('cordova/exec'),
	MediaDeviceInfo = _dereq_('./MediaDeviceInfo'),
	Errors = _dereq_('./Errors');


function enumerateDevices() {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('cordova.plugins.iosrtc.enumerateDevices', arguments);

	return new Promise(function (resolve) {
		function onResultOK(data) {
			debug('enumerateDevices() | success');
			resolve(getMediaDeviceInfos(data.devices));
		}

		exec(onResultOK, null, 'iosrtcPlugin', 'enumerateDevices', []);
	});
}


/**
 * Private API.
 */


function getMediaDeviceInfos(devices) {
	debug('getMediaDeviceInfos() | [devices:%o]', devices);

	var id,
		mediaDeviceInfos = [];

	for (id in devices) {
		if (devices.hasOwnProperty(id)) {
			mediaDeviceInfos.push(new MediaDeviceInfo(devices[id]));
		}
	}

	return mediaDeviceInfos;
}

},{"./Errors":1,"./MediaDeviceInfo":3,"cordova/exec":undefined,"debug":18}],15:[function(_dereq_,module,exports){
/**
 * Expose the getUserMedia function.
 */
module.exports = getUserMedia;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:getUserMedia'),
	debugerror = _dereq_('debug')('iosrtc:ERROR:getUserMedia'),
	exec = _dereq_('cordova/exec'),
	MediaStream = _dereq_('./MediaStream'),
	Errors = _dereq_('./Errors');

function isPositiveInteger(number) {
	return typeof number === 'number' && number >= 0 && number % 1 === 0;
}

function isPositiveFloat(number) {
	return typeof number === 'number' && number >= 0;
}


function getUserMedia(constraints) {

	// Detect callback usage to assist 5.0.1 to 5.0.2 migration
	// TODO remove on 6.0.0
	Errors.detectDeprecatedCallbaksUsage('cordova.plugins.iosrtc.getUserMedia', arguments);

	debug('[original constraints:%o]', constraints);

	var
		audioRequested = false,
		videoRequested = false,
		newConstraints = {};

	if (
		typeof constraints !== 'object' ||
			(!constraints.hasOwnProperty('audio') && !constraints.hasOwnProperty('video'))
	) {
		return new Promise(function (resolve, reject) {
			reject(new Errors.MediaStreamError('constraints must be an object with at least "audio" or "video" keys'));
		});
	}

	if (constraints.audio) {
		audioRequested = true;
	}

	if (constraints.video) {
		videoRequested = true;
	}

	// https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints
	// Example:
	//
	// getUserMedia({
	//  audio: {
	//      deviceId: 'azer-asdf-zxcv',
	//  },
	//  video: {
	//      deviceId: 'qwer-asdf-zxcv',
	//      aspectRatio: 1.777.
	//      facingMode: 'user',
	//      width: {
	//          min: 400,
	//          max: 600
	//      },
	//      frameRate: {
	//          min: 1.0,
	//          max: 60.0
	//      }
	//  }
	// });

	/*
	// See: https://www.w3.org/TR/mediacapture-streams/#media-track-constraints
	dictionary MediaTrackConstraintSet {
	 ConstrainULong     width;
	 ConstrainULong     height;
	 ConstrainDouble    aspectRatio;
	 ConstrainDouble    frameRate;
	 ConstrainDOMString facingMode;
	 ConstrainDOMString resizeMode;
	 ConstrainULong     sampleRate;
	 ConstrainULong     sampleSize;
	 ConstrainBoolean   echoCancellation;
	 ConstrainBoolean   autoGainControl;
	 ConstrainBoolean   noiseSuppression;
	 ConstrainDouble    latency;
	 ConstrainULong     channelCount;
	 ConstrainDOMString deviceId;
	 ConstrainDOMString groupId;
	};

	 // typedef ([Clamp] unsigned long or ConstrainULongRange) ConstrainULong;
	 // We convert unsigned long to ConstrainULongRange.exact

	 dictionary ULongRange {
		[Clamp] unsigned long max;
		[Clamp] unsigned long min;
	 };

	 dictionary ConstrainULongRange : ULongRange {
		  [Clamp] unsigned long exact;
		  [Clamp] unsigned long ideal;
	 };

	 // See: https://www.w3.org/TR/mediacapture-streams/#dom-doublerange
	 // typedef (double or ConstrainDoubleRange) ConstrainDouble;
	 // We convert double to ConstrainDoubleRange.exact
	 dictionary ConstrainDouble {
		double max;
		double min;
	 };

	 dictionary ConstrainDoubleRange : DoubleRange {
		double exact;
		double ideal;
	 };

	 // typedef (boolean or ConstrainBooleanParameters) ConstrainBoolean;
	 dictionary ConstrainBooleanParameters {
		boolean exact;
		boolean ideal;
	 };

	 // typedef (DOMString or sequence<DOMString> or ConstrainDOMStringParameters) ConstrainDOMString;
	 // We convert DOMString to ConstrainDOMStringParameters.exact
	 dictionary ConstrainDOMStringParameters {
		(DOMString or sequence<DOMString>) exact;
		(DOMString or sequence<DOMString>) ideal;
	 };
	*/

	// Get video constraints
	if (videoRequested) {

		// Handle object video constraints
		newConstraints.video = {};

		// Handle Stupid not up-to-date webrtc-adapter
		// Note: Firefox [38+] does support a subset of constraints with getUserMedia(), but not the outdated syntax that Chrome and Opera are using.
		// The mandatory / optional syntax was deprecated a in 2014, and minWidth and minHeight the year before that.

		if (
			typeof constraints.video === 'object' &&
				(typeof constraints.video.optional === 'object' || typeof constraints.video.mandatory === 'object')
		) {

			if (
				typeof constraints.video.optional === 'object'
			) {
				if (typeof constraints.video.optional.sourceId === 'string') {
					newConstraints.video.deviceId = {
						ideal: constraints.video.optional.sourceId
					};
				} else if (
					Array.isArray(constraints.video.optional) &&
						typeof constraints.video.optional[0] === 'object' &&
							typeof constraints.video.optional[0].sourceId === 'string'
				) {
					newConstraints.video.deviceId = {
						ideal: constraints.video.optional[0].sourceId
					};
				}
			} else if (
				constraints.video.mandatory &&
					typeof constraints.video.mandatory.sourceId === 'string'
			) {
				newConstraints.video.deviceId = {
					exact: constraints.video.mandatory.sourceId
				};
			}

			// Only apply mandatory over optional
			var videoConstraints = constraints.video.mandatory || constraints.video.optional;
			videoConstraints = Array.isArray(videoConstraints) ? videoConstraints[0] : videoConstraints;

			if (isPositiveInteger(videoConstraints.minWidth)) {
				newConstraints.video.width = {
					min: videoConstraints.minWidth
				};
			}

			if (isPositiveInteger(videoConstraints.minHeight)) {
				newConstraints.video.height = {
					min: videoConstraints.minHeight
				};
			}

			if (isPositiveFloat(videoConstraints.minFrameRate)) {
				newConstraints.video.frameRate = {
					min: parseFloat(videoConstraints.minFrameRate, 10)
				};
			}

			if (isPositiveFloat(videoConstraints.maxFrameRate)) {
				newConstraints.video.frameRate = newConstraints.video.frameRate || {};
				newConstraints.video.frameRate.max = parseFloat(videoConstraints.maxFrameRate, 10);
			}
		}

		// Get requested video deviceId.
		if (typeof constraints.video.deviceId === 'string') {
			newConstraints.video.deviceId = {
				exact: constraints.video.deviceId
			};

		// Also check video sourceId (mangled by adapter.js).
		} else if (typeof constraints.video.sourceId === 'string') {
			newConstraints.video.deviceId = {
				exact: constraints.video.sourceId
			};

		// Also check deviceId.(exact|ideal)
		} else if (typeof constraints.video.deviceId === 'object') {
			if (!!constraints.video.deviceId.exact) {
				newConstraints.video.deviceId = {
					exact: Array.isArray(constraints.video.deviceId.exact) ?
						constraints.video.deviceId.exact[0] : constraints.video.deviceId.exact
				};
			} else if (!!constraints.video.deviceId.ideal) {
				newConstraints.video.deviceId = {
					ideal: Array.isArray(constraints.video.deviceId.ideal) ?
							constraints.video.deviceId.ideal[0] : constraints.video.deviceId.ideal
				};
			}
		}

		// Get requested width min/max, exact.
		if (typeof constraints.video.width === 'object') {
			newConstraints.video.width = {};
			if (isPositiveInteger(constraints.video.width.min)) {
				newConstraints.video.width.min = constraints.video.width.min;
			}
			if (isPositiveInteger(constraints.video.width.max)) {
				newConstraints.video.width.max = constraints.video.width.max;
			}
			if (isPositiveInteger(constraints.video.width.exact)) {
				newConstraints.video.width.exact = constraints.video.width.exact;
			}
			if (isPositiveInteger(constraints.video.width.ideal)) {
				newConstraints.video.width.ideal = constraints.video.width.ideal;
			}

		// Get requested width long as exact
		} else if (isPositiveInteger(constraints.video.width)) {
			newConstraints.video.width = {
				exact: constraints.video.width
			};
		}

		// Get requested height min/max, exact.
		if (typeof constraints.video.height === 'object') {
			newConstraints.video.height = {};
			if (isPositiveInteger(constraints.video.height.min)) {
				newConstraints.video.height.min = constraints.video.height.min;
			}
			if (isPositiveInteger(constraints.video.height.max)) {
				newConstraints.video.height.max = constraints.video.height.max;
			}
			if (isPositiveInteger(constraints.video.height.exact)) {
				newConstraints.video.height.exact = constraints.video.height.exact;
			}
			if (isPositiveInteger(constraints.video.height.ideal)) {
				newConstraints.video.height.ideal = constraints.video.height.ideal;
			}

		// Get requested height long as exact
		} else if (isPositiveInteger(constraints.video.height)) {
			newConstraints.video.height = {
				exact: constraints.video.height
			};
		}

		// Get requested frameRate min/max.
		if (typeof constraints.video.frameRate === 'object') {
			newConstraints.video.frameRate = {};
			if (isPositiveFloat(constraints.video.frameRate.min)) {
				newConstraints.video.frameRate.min = parseFloat(constraints.video.frameRate.min, 10);
			}
			if (isPositiveFloat(constraints.video.frameRate.max)) {
				newConstraints.video.frameRate.max = parseFloat(constraints.video.frameRate.max, 10);
			}
			if (isPositiveInteger(constraints.video.frameRate.exact)) {
				newConstraints.video.frameRate.exact = constraints.video.frameRate.exact;
			}
			if (isPositiveInteger(constraints.video.frameRate.ideal)) {
				newConstraints.video.frameRate.ideal = constraints.video.frameRate.ideal;
			}

		// Get requested frameRate double as exact
		} else if (isPositiveFloat(constraints.video.frameRate)) {
			newConstraints.video.frameRate = {
				exact: parseFloat(constraints.video.frameRate, 10)
			};
		}

		// get aspectRatio (e.g 1.7777777777777777)
		// TODO ConstrainDouble min, max
		if (typeof constraints.video.aspectRatio === 'object') {
			if (isPositiveFloat(constraints.video.aspectRatio.min)) {
				newConstraints.video.aspectRatio.min = parseFloat(constraints.video.aspectRatio.min, 10);
			}
			if (isPositiveFloat(constraints.video.aspectRatio.max)) {
				newConstraints.video.aspectRatio.max = parseFloat(constraints.video.aspectRatio.max, 10);
			}
			if (isPositiveInteger(constraints.video.aspectRatio.exact)) {
				newConstraints.video.aspectRatio.exact = constraints.video.aspectRatio.exact;
			}
			if (isPositiveInteger(constraints.video.aspectRatio.ideal)) {
				newConstraints.video.aspectRatio.ideal = constraints.video.aspectRatio.ideal;
			}
		} else if (isPositiveFloat(constraints.video.aspectRatio)) {
			newConstraints.video.aspectRatio = {
				exact: parseFloat(constraints.video.aspectRatio, 10)
			};
		}

		// get facingMode (e.g environment, user)
		// TODO ConstrainDOMStringParameters ideal, exact
		if (typeof constraints.video.facingMode === 'string') {
			newConstraints.video.facingMode = {
				exact: constraints.video.facingMode
			};
		} else if (typeof constraints.video.facingMode === 'object') {
			if (typeof constraints.video.facingMode.exact === 'string') {
				newConstraints.video.facingMode = {
					exact: constraints.video.facingMode.exact
				};
			} else if (typeof constraints.video.facingMode.ideal === 'string') {
				newConstraints.video.facingMode = {
					ideal: constraints.video.facingMode.ideal
				};
			}
		}
	}

	// Get audio constraints
	if (audioRequested) {

		// Handle object audio constraints
		newConstraints.audio = {};

		// Handle Stupid not up-to-date webrtc-adapter
		// Note: Firefox [38+] does support a subset of constraints with getUserMedia(), but not the outdated syntax that Chrome and Opera are using.
		// The mandatory / optional syntax was deprecated a in 2014, and minWidth and minHeight the year before that.
		if (
			typeof constraints.audio === 'object' &&
				(typeof constraints.audio.optional === 'object' || typeof constraints.audio.mandatory === 'object')
		) {
			if (
				typeof constraints.audio.optional === 'object'
			) {
				if (typeof constraints.audio.optional.sourceId === 'string') {
					newConstraints.audio.deviceId = {
						ideal: constraints.audio.optional.sourceId
					};
				} else if (
					Array.isArray(constraints.audio.optional) &&
						typeof constraints.audio.optional[0] === 'object' &&
							typeof constraints.audio.optional[0].sourceId === 'string'
				) {
					newConstraints.audio.deviceId = {
						ideal: constraints.audio.optional[0].sourceId
					};
				}
			} else if (
				constraints.audio.mandatory &&
					typeof constraints.audio.mandatory.sourceId === 'string'
			) {
				newConstraints.audio.deviceId = {
					exact: constraints.audio.mandatory.sourceId
				};
			}
		}

		// Get requested audio deviceId.
		if (typeof constraints.audio.deviceId === 'string') {
			newConstraints.audio.deviceId = {
				exact: constraints.audio.deviceId
			};

		// Also check audio sourceId (mangled by adapter.js).
		} else if (typeof constraints.audio.sourceId === 'string') {
			newConstraints.audio.deviceId = {
				exact: constraints.audio.sourceId
			};

		// Also check deviceId.(exact|ideal)
		} else if (typeof constraints.audio.deviceId === 'object') {
			if (!!constraints.audio.deviceId.exact) {
				newConstraints.audio.deviceId = {
					exact: Array.isArray(constraints.audio.deviceId.exact) ?
						constraints.audio.deviceId.exact[0] : constraints.audio.deviceId.exact
				};
			} else if (!!constraints.audio.deviceId.ideal) {
				newConstraints.audio.deviceId = {
					ideal: Array.isArray(constraints.audio.deviceId.ideal) ?
							constraints.audio.deviceId.ideal[0] : constraints.audio.deviceId.ideal
				};
			}
		}
	}

	debug('[computed constraints:%o]', newConstraints);

	return new Promise(function (resolve, reject) {
		function onResultOK(data) {
			debug('getUserMedia() | success');
			var stream = MediaStream.create(data.stream);
			resolve(stream);
			// Emit "connected" on the stream.
			stream.emitConnected();
		}

		function onResultError(error) {
			debugerror('getUserMedia() | failure: %s', error);
			reject(new Errors.MediaStreamError('getUserMedia() failed: ' + error));
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'getUserMedia', [newConstraints]);
	});
}
},{"./Errors":1,"./MediaStream":4,"cordova/exec":undefined,"debug":18}],16:[function(_dereq_,module,exports){
(function (global){
/**
 * Variables.
 */

var
	// Dictionary of MediaStreamRenderers.
	// - key: MediaStreamRenderer id.
	// - value: MediaStreamRenderer.
	mediaStreamRenderers = {},

	// Dictionary of MediaStreams.
	// - key: MediaStream blobId.
	// - value: MediaStream.
	mediaStreams = {},


/**
 * Dependencies.
 */
	debug                  = _dereq_('debug')('iosrtc'),
	exec                   = _dereq_('cordova/exec'),
	domready               = _dereq_('domready'),

	getUserMedia           = _dereq_('./getUserMedia'),
	enumerateDevices       = _dereq_('./enumerateDevices'),
	RTCPeerConnection      = _dereq_('./RTCPeerConnection'),
	RTCSessionDescription  = _dereq_('./RTCSessionDescription'),
	RTCIceCandidate        = _dereq_('./RTCIceCandidate'),
	MediaStream            = _dereq_('./MediaStream'),
	MediaStreamTrack       = _dereq_('./MediaStreamTrack'),
	videoElementsHandler   = _dereq_('./videoElementsHandler');


/**
 * Expose the iosrtc object.
 */
module.exports = {
	// Expose WebRTC classes and functions.
	getUserMedia:          getUserMedia,
	enumerateDevices:      enumerateDevices,
	getMediaDevices:       enumerateDevices,  // TMP
	RTCPeerConnection:     RTCPeerConnection,
	RTCSessionDescription: RTCSessionDescription,
	RTCIceCandidate:       RTCIceCandidate,
	MediaStream:           MediaStream,
	MediaStreamTrack:      MediaStreamTrack,

	// Expose a function to refresh current videos rendering a MediaStream.
	refreshVideos:         videoElementsHandler.refreshVideos,

	// Expose a function to handle a video not yet inserted in the DOM.
	observeVideo:          videoElementsHandler.observeVideo,

	// Select audio output (earpiece or speaker).
	selectAudioOutput:     selectAudioOutput,

	// turnOnSpeaker with options
	turnOnSpeaker: turnOnSpeaker,

	// Checking permision (audio and camera)
	requestPermission: requestPermission,

	// Expose a function to pollute window and naigator namespaces.
	registerGlobals:       registerGlobals,

	// Expose the debug module.
	debug:                 _dereq_('debug'),

	// Debug function to see what happens internally.
	dump:                  dump,

	// Debug Stores to see what happens internally.
	mediaStreamRenderers:  mediaStreamRenderers,
	mediaStreams:          mediaStreams
};


domready(function () {
	// Let the MediaStream class and the videoElementsHandler share same MediaStreams container.
	MediaStream.setMediaStreams(mediaStreams);
	videoElementsHandler(mediaStreams, mediaStreamRenderers);

	// refreshVideos on device orientation change to resize peers video
	// while local video will resize du orientation change
	window.addEventListener('resize', function () {
		videoElementsHandler.refreshVideos();
	});
});

function selectAudioOutput(output) {
	debug('selectAudioOutput() | [output:"%s"]', output);

	switch (output) {
		case 'earpiece':
			exec(null, null, 'iosrtcPlugin', 'selectAudioOutputEarpiece', []);
			break;
		case 'speaker':
			exec(null, null, 'iosrtcPlugin', 'selectAudioOutputSpeaker', []);
			break;
		default:
			throw new Error('output must be "earpiece" or "speaker"');
	}
}

function turnOnSpeaker(isTurnOn) {
	debug('turnOnSpeaker() | [isTurnOn:"%s"]', isTurnOn);

	exec(null, null, 'iosrtcPlugin', "RTCTurnOnSpeaker", [isTurnOn]);
}

function requestPermission(needMic, needCamera, callback) {
	debug('requestPermission() | [needMic:"%s", needCamera:"%s"]', needMic, needCamera);

	function ok() {
		callback(true);
	}

	function error() {
		callback(false);
	}
	exec(ok, error, 'iosrtcPlugin', "RTCRequestPermission", [needMic, needCamera]);
}

function callbackifyMethod(originalMethod) {
	return function () {
		var success, failure,
		  originalArgs = Array.prototype.slice.call(arguments);

		var callbackArgs = [];
		originalArgs.forEach(function (arg) {
			if (typeof arg === 'function') {
				if (!success) {
					success = arg;
				} else {
					failure = arg;
				}
			} else {
				callbackArgs.push(arg);
			}
		});

		var promiseResult = originalMethod.apply(this, callbackArgs);

		// Only apply then if callback success available
		if (typeof success === 'function') {
			promiseResult = promiseResult.then(success);
		}

		// Only apply catch if callback failure available
		if (typeof failure === 'function') {
			promiseResult = promiseResult.catch(failure);
		}

		return promiseResult;
	};
}

function callbackifyPrototype(proto, method) {
	var originalMethod = proto[method];
	proto[method] = callbackifyMethod(originalMethod);
}

function restoreCallbacksSupport() {
	debug('restoreCallbacksSupport()');
	getUserMedia = callbackifyMethod(getUserMedia);
	enumerateDevices = callbackifyMethod(enumerateDevices);
	callbackifyPrototype(RTCPeerConnection.prototype, 'createAnswer');
	callbackifyPrototype(RTCPeerConnection.prototype, 'createOffer');
	callbackifyPrototype(RTCPeerConnection.prototype, 'setRemoteDescription');
	callbackifyPrototype(RTCPeerConnection.prototype, 'setLocalDescription');
	callbackifyPrototype(RTCPeerConnection.prototype, 'addIceCandidate');
}

function registerGlobals(doNotRestoreCallbacksSupport) {
	debug('registerGlobals()');

	if (!global.navigator) {
		global.navigator = {};
	}

	if (!navigator.mediaDevices) {
		navigator.mediaDevices = {};
	}

	// Restore Callback support
	if (!doNotRestoreCallbacksSupport) {
		restoreCallbacksSupport();
	}

	navigator.getUserMedia                  = getUserMedia;
	navigator.webkitGetUserMedia            = getUserMedia;
	navigator.mediaDevices.getUserMedia     = getUserMedia;
	navigator.mediaDevices.enumerateDevices = enumerateDevices;

	window.RTCPeerConnection                = RTCPeerConnection;
	window.webkitRTCPeerConnection          = RTCPeerConnection;
	window.RTCSessionDescription            = RTCSessionDescription;
	window.RTCIceCandidate                  = RTCIceCandidate;
	window.MediaStream                      = MediaStream;
	window.webkitMediaStream                = MediaStream;
	window.MediaStreamTrack                 = MediaStreamTrack;
}

function dump() {
	exec(null, null, 'iosrtcPlugin', 'dump', []);
}

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./MediaStream":4,"./MediaStreamTrack":6,"./RTCIceCandidate":9,"./RTCPeerConnection":10,"./RTCSessionDescription":11,"./enumerateDevices":14,"./getUserMedia":15,"./videoElementsHandler":17,"cordova/exec":undefined,"debug":18,"domready":20}],17:[function(_dereq_,module,exports){
/**
 * Expose a function that must be called when the library is loaded.
 * And also a helper function.
 */
module.exports = videoElementsHandler;
module.exports.observeVideo = observeVideo;
module.exports.refreshVideos = refreshVideos;


/**
 * Dependencies.
 */
var
	debug = _dereq_('debug')('iosrtc:videoElementsHandler'),
	MediaStreamRenderer = _dereq_('./MediaStreamRenderer'),


/**
 * Local variables.
 */

	// Dictionary of MediaStreamRenderers (provided via module argument).
	// - key: MediaStreamRenderer id.
	// - value: MediaStreamRenderer.
	mediaStreamRenderers,

	// Dictionary of MediaStreams (provided via module argument).
	// - key: MediaStream blobId.
	// - value: MediaStream.
	mediaStreams,

	// Video element mutation observer.
	videoObserver = new MutationObserver(function (mutations) {
		var i, numMutations, mutation, video;

		for (i = 0, numMutations = mutations.length; i < numMutations; i++) {
			mutation = mutations[i];

			// HTML video element.
			video = mutation.target;

			// .srcObject removed.
			if (!video.srcObject) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);
				continue;
			}

			handleVideo(video);
		}
	}),

	// DOM mutation observer.
	domObserver = new MutationObserver(function (mutations) {
		var
			i, numMutations, mutation,
			j, numNodes, node;

		for (i = 0, numMutations = mutations.length; i < numMutations; i++) {
			mutation = mutations[i];

			// Check if there has been addition or deletion of nodes.
			if (mutation.type !== 'childList') {
				continue;
			}

			// Check added nodes.
			for (j = 0, numNodes = mutation.addedNodes.length; j < numNodes; j++) {
				node = mutation.addedNodes[j];

				checkNewNode(node);
			}

			// Check removed nodes.
			for (j = 0, numNodes = mutation.removedNodes.length; j < numNodes; j++) {
				node = mutation.removedNodes[j];

				checkRemovedNode(node);
			}
		}

		function checkNewNode(node) {
			var j, childNode;

			if (node.nodeName === 'VIDEO') {
				debug('new video element added');

				// Avoid same node firing more than once (really, may happen in some cases).
				if (node._iosrtcVideoHandled) {
					return;
				}
				node._iosrtcVideoHandled = true;

				// Observe changes in the video element.
				observeVideo(node);
			} else {
				for (j = 0; j < node.childNodes.length; j++) {
					childNode = node.childNodes.item(j);

					checkNewNode(childNode);
				}
			}
		}

		function checkRemovedNode(node) {
			var j, childNode;

			if (node.nodeName === 'VIDEO') {
				debug('video element removed');

				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(node);
				delete node._iosrtcVideoHandled;
			} else {
				for (j = 0; j < node.childNodes.length; j++) {
					childNode = node.childNodes.item(j);

					checkRemovedNode(childNode);
				}
			}
		}
	});

function refreshVideos() {
	debug('refreshVideos()');

	var id;

	for (id in mediaStreamRenderers) {
		if (mediaStreamRenderers.hasOwnProperty(id)) {
			mediaStreamRenderers[id].refresh();
		}
	}
}

function videoElementsHandler(_mediaStreams, _mediaStreamRenderers) {
	var
		existingVideos = document.querySelectorAll('video'),
		i, len, video;

	mediaStreams = _mediaStreams;
	mediaStreamRenderers = _mediaStreamRenderers;

	// Search the whole document for already existing HTML video elements and observe them.
	for (i = 0, len = existingVideos.length; i < len; i++) {
		video = existingVideos.item(i);

		debug('video element found');

		observeVideo(video);
	}

	// Observe the whole document for additions of new HTML video elements and observe them.
	domObserver.observe(document, {
		// Set to true if additions and removals of the target node's child elements (including text nodes) are to
		// be observed.
		childList: true,
		// Set to true if mutations to target's attributes are to be observed.
		attributes: false,
		// Set to true if mutations to target's data are to be observed.
		characterData: false,
		// Set to true if mutations to not just target, but also target's descendants are to be observed.
		subtree: true,
		// Set to true if attributes is set to true and target's attribute value before the mutation needs to be
		// recorded.
		attributeOldValue: false,
		// Set to true if characterData is set to true and target's data before the mutation needs to be recorded.
		characterDataOldValue: false
		// Set to an array of attribute local names (without namespace) if not all attribute mutations need to be
		// observed.
		// attributeFilter:
	});
}


function observeVideo(video) {
	debug('observeVideo()');

	// If the video already has a srcObject property but is not yet handled by the plugin
	// then handle it now.
	if ((video.srcObject) && !video._iosrtcMediaStreamRendererId) {
		handleVideo(video);
	}

	// Add .srcObject observer to the video element.
	videoObserver.observe(video, {
		// Set to true if additions and removals of the target node's child elements (including text
		// nodes) are to be observed.
		childList: false,
		// Set to true if mutations to target's attributes are to be observed.
		attributes: true,
		// Set to true if mutations to target's data are to be observed.
		characterData: false,
		// Set to true if mutations to not just target, but also target's descendants are to be observed.
		subtree: false,
		// Set to true if attributes is set to true and target's attribute value before the mutation
		// needs to be recorded.
		attributeOldValue: false,
		// Set to true if characterData is set to true and target's data before the mutation needs to be
		// recorded.
		characterDataOldValue: false,
		// Set to an array of attribute local names (without namespace) if not all attribute mutations
		// need to be observed.
		// srcObject DO not trigger MutationObserver
		attributeFilter: ['srcObject']
	});

	// MutationObserver fail to trigger when using srcObject on ony tested browser.
	// But video.srcObject = new MediaStream() will trigger onloadstart and
	// video.srcObject = null will trigger onemptied events.

	video.addEventListener('loadstart', function () {
		if (video.srcObject && !video._iosrtcMediaStreamRendererId) {
			// If this video element was NOT previously handling a MediaStreamRenderer, release it.
			handleVideo(video);
		} else if (video.srcObject && video._iosrtcMediaStreamRendererId) {
			// The video element has received a new srcObject.
			var stream = video.srcObject;
			if (stream && typeof stream.getBlobId === 'function') {
				// Release previous renderer
				releaseMediaStreamRenderer(video);
				// Install new renderer
				provideMediaStreamRenderer(video, stream.getBlobId());
			}
		}
	});

	video.addEventListener('emptied', function () {
		if (!video.srcObject && video._iosrtcMediaStreamRendererId) {
			// If this video element was previously handling a MediaStreamRenderer, release it.
			releaseMediaStreamRenderer(video);
		}
	});
}


/**
 * Private API.
 */

function handleVideo(video) {
	var
		stream;

	// The app has set video.srcObject.
	if (video.srcObject) {
		stream = video.srcObject;
		if (stream && typeof stream.getBlobId === 'function') {

			if (!stream.getBlobId()) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);

				return;
			}

			provideMediaStreamRenderer(video, stream.getBlobId());
		}
	}
}


function provideMediaStreamRenderer(video, mediaStreamBlobId) {
	var
		mediaStream = mediaStreams[mediaStreamBlobId],
		mediaStreamRenderer = mediaStreamRenderers[video._iosrtcMediaStreamRendererId];

	if (!mediaStream) {
		releaseMediaStreamRenderer(video);

		return;
	}

	if (mediaStreamRenderer) {
		mediaStreamRenderer.render(mediaStream);
	} else {
		mediaStreamRenderer = new MediaStreamRenderer(video);
		mediaStreamRenderer.render(mediaStream);

		mediaStreamRenderers[mediaStreamRenderer.id] = mediaStreamRenderer;
		video._iosrtcMediaStreamRendererId = mediaStreamRenderer.id;
	}

	// Close the MediaStreamRenderer of this video if it emits "close" event.
	mediaStreamRenderer.addEventListener('close', function () {
		if (mediaStreamRenderers[video._iosrtcMediaStreamRendererId] !== mediaStreamRenderer) {
			return;
		}

		releaseMediaStreamRenderer(video);
	});

	// Override some <video> properties.
	// NOTE: This is a terrible hack but it works.
	Object.defineProperties(video, {
		videoWidth: {
			configurable: true,
			get: function () {
				return mediaStreamRenderer.videoWidth || 0;
			}
		},
		videoHeight: {
			configurable: true,
			get: function () {
				return mediaStreamRenderer.videoHeight || 0;
			}
		},
		readyState: {
			configurable: true,
			get: function () {
				if (mediaStreamRenderer && mediaStreamRenderer.stream && mediaStreamRenderer.stream.connected) {
					return video.HAVE_ENOUGH_DATA;
				} else {
					return video.HAVE_NOTHING;
				}
			}
		}
	});
}

function releaseMediaStreamRenderer(video) {
	if (!video._iosrtcMediaStreamRendererId) {
		return;
	}

	var mediaStreamRenderer = mediaStreamRenderers[video._iosrtcMediaStreamRendererId];

	if (mediaStreamRenderer) {
		delete mediaStreamRenderers[video._iosrtcMediaStreamRendererId];
		mediaStreamRenderer.close();
	}

	delete video._iosrtcMediaStreamRendererId;

	// Remove overrided <video> properties.
	delete video.videoWidth;
	delete video.videoHeight;
	delete video.readyState;
}

},{"./MediaStreamRenderer":5,"debug":18}],18:[function(_dereq_,module,exports){
(function (process){
/* eslint-env browser */

/**
 * This is the web browser implementation of `debug()`.
 */

exports.log = log;
exports.formatArgs = formatArgs;
exports.save = save;
exports.load = load;
exports.useColors = useColors;
exports.storage = localstorage();

/**
 * Colors.
 */

exports.colors = [
	'#0000CC',
	'#0000FF',
	'#0033CC',
	'#0033FF',
	'#0066CC',
	'#0066FF',
	'#0099CC',
	'#0099FF',
	'#00CC00',
	'#00CC33',
	'#00CC66',
	'#00CC99',
	'#00CCCC',
	'#00CCFF',
	'#3300CC',
	'#3300FF',
	'#3333CC',
	'#3333FF',
	'#3366CC',
	'#3366FF',
	'#3399CC',
	'#3399FF',
	'#33CC00',
	'#33CC33',
	'#33CC66',
	'#33CC99',
	'#33CCCC',
	'#33CCFF',
	'#6600CC',
	'#6600FF',
	'#6633CC',
	'#6633FF',
	'#66CC00',
	'#66CC33',
	'#9900CC',
	'#9900FF',
	'#9933CC',
	'#9933FF',
	'#99CC00',
	'#99CC33',
	'#CC0000',
	'#CC0033',
	'#CC0066',
	'#CC0099',
	'#CC00CC',
	'#CC00FF',
	'#CC3300',
	'#CC3333',
	'#CC3366',
	'#CC3399',
	'#CC33CC',
	'#CC33FF',
	'#CC6600',
	'#CC6633',
	'#CC9900',
	'#CC9933',
	'#CCCC00',
	'#CCCC33',
	'#FF0000',
	'#FF0033',
	'#FF0066',
	'#FF0099',
	'#FF00CC',
	'#FF00FF',
	'#FF3300',
	'#FF3333',
	'#FF3366',
	'#FF3399',
	'#FF33CC',
	'#FF33FF',
	'#FF6600',
	'#FF6633',
	'#FF9900',
	'#FF9933',
	'#FFCC00',
	'#FFCC33'
];

/**
 * Currently only WebKit-based Web Inspectors, Firefox >= v31,
 * and the Firebug extension (any Firefox version) are known
 * to support "%c" CSS customizations.
 *
 * TODO: add a `localStorage` variable to explicitly enable/disable colors
 */

// eslint-disable-next-line complexity
function useColors() {
	// NB: In an Electron preload script, document will be defined but not fully
	// initialized. Since we know we're in Chrome, we'll just detect this case
	// explicitly
	if (typeof window !== 'undefined' && window.process && (window.process.type === 'renderer' || window.process.__nwjs)) {
		return true;
	}

	// Internet Explorer and Edge do not support colors.
	if (typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.toLowerCase().match(/(edge|trident)\/(\d+)/)) {
		return false;
	}

	// Is webkit? http://stackoverflow.com/a/16459606/376773
	// document is undefined in react-native: https://github.com/facebook/react-native/pull/1632
	return (typeof document !== 'undefined' && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance) ||
		// Is firebug? http://stackoverflow.com/a/398120/376773
		(typeof window !== 'undefined' && window.console && (window.console.firebug || (window.console.exception && window.console.table))) ||
		// Is firefox >= v31?
		// https://developer.mozilla.org/en-US/docs/Tools/Web_Console#Styling_messages
		(typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/) && parseInt(RegExp.$1, 10) >= 31) ||
		// Double check webkit in userAgent just in case we are in a worker
		(typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/));
}

/**
 * Colorize log arguments if enabled.
 *
 * @api public
 */

function formatArgs(args) {
	args[0] = (this.useColors ? '%c' : '') +
		this.namespace +
		(this.useColors ? ' %c' : ' ') +
		args[0] +
		(this.useColors ? '%c ' : ' ') +
		'+' + module.exports.humanize(this.diff);

	if (!this.useColors) {
		return;
	}

	const c = 'color: ' + this.color;
	args.splice(1, 0, c, 'color: inherit');

	// The final "%c" is somewhat tricky, because there could be other
	// arguments passed either before or after the %c, so we need to
	// figure out the correct index to insert the CSS into
	let index = 0;
	let lastC = 0;
	args[0].replace(/%[a-zA-Z%]/g, match => {
		if (match === '%%') {
			return;
		}
		index++;
		if (match === '%c') {
			// We only are interested in the *last* %c
			// (the user may have provided their own)
			lastC = index;
		}
	});

	args.splice(lastC, 0, c);
}

/**
 * Invokes `console.log()` when available.
 * No-op when `console.log` is not a "function".
 *
 * @api public
 */
function log(...args) {
	// This hackery is required for IE8/9, where
	// the `console.log` function doesn't have 'apply'
	return typeof console === 'object' &&
		console.log &&
		console.log(...args);
}

/**
 * Save `namespaces`.
 *
 * @param {String} namespaces
 * @api private
 */
function save(namespaces) {
	try {
		if (namespaces) {
			exports.storage.setItem('debug', namespaces);
		} else {
			exports.storage.removeItem('debug');
		}
	} catch (error) {
		// Swallow
		// XXX (@Qix-) should we be logging these?
	}
}

/**
 * Load `namespaces`.
 *
 * @return {String} returns the previously persisted debug modes
 * @api private
 */
function load() {
	let r;
	try {
		r = exports.storage.getItem('debug');
	} catch (error) {
		// Swallow
		// XXX (@Qix-) should we be logging these?
	}

	// If debug isn't set in LS, and we're in Electron, try to load $DEBUG
	if (!r && typeof process !== 'undefined' && 'env' in process) {
		r = process.env.DEBUG;
	}

	return r;
}

/**
 * Localstorage attempts to return the localstorage.
 *
 * This is necessary because safari throws
 * when a user disables cookies/localstorage
 * and you attempt to access it.
 *
 * @return {LocalStorage}
 * @api private
 */

function localstorage() {
	try {
		// TVMLKit (Apple TV JS Runtime) does not have a window object, just localStorage in the global context
		// The Browser also has localStorage in the global context.
		return localStorage;
	} catch (error) {
		// Swallow
		// XXX (@Qix-) should we be logging these?
	}
}

module.exports = _dereq_('./common')(exports);

const {formatters} = module.exports;

/**
 * Map %j to `JSON.stringify()`, since no Web Inspectors do that by default.
 */

formatters.j = function (v) {
	try {
		return JSON.stringify(v);
	} catch (error) {
		return '[UnexpectedJSONParseError]: ' + error.message;
	}
};

}).call(this,_dereq_('_process'))
},{"./common":19,"_process":22}],19:[function(_dereq_,module,exports){

/**
 * This is the common logic for both the Node.js and web browser
 * implementations of `debug()`.
 */

function setup(env) {
	createDebug.debug = createDebug;
	createDebug.default = createDebug;
	createDebug.coerce = coerce;
	createDebug.disable = disable;
	createDebug.enable = enable;
	createDebug.enabled = enabled;
	createDebug.humanize = _dereq_('ms');

	Object.keys(env).forEach(key => {
		createDebug[key] = env[key];
	});

	/**
	* Active `debug` instances.
	*/
	createDebug.instances = [];

	/**
	* The currently active debug mode names, and names to skip.
	*/

	createDebug.names = [];
	createDebug.skips = [];

	/**
	* Map of special "%n" handling functions, for the debug "format" argument.
	*
	* Valid key names are a single, lower or upper-case letter, i.e. "n" and "N".
	*/
	createDebug.formatters = {};

	/**
	* Selects a color for a debug namespace
	* @param {String} namespace The namespace string for the for the debug instance to be colored
	* @return {Number|String} An ANSI color code for the given namespace
	* @api private
	*/
	function selectColor(namespace) {
		let hash = 0;

		for (let i = 0; i < namespace.length; i++) {
			hash = ((hash << 5) - hash) + namespace.charCodeAt(i);
			hash |= 0; // Convert to 32bit integer
		}

		return createDebug.colors[Math.abs(hash) % createDebug.colors.length];
	}
	createDebug.selectColor = selectColor;

	/**
	* Create a debugger with the given `namespace`.
	*
	* @param {String} namespace
	* @return {Function}
	* @api public
	*/
	function createDebug(namespace) {
		let prevTime;

		function debug(...args) {
			// Disabled?
			if (!debug.enabled) {
				return;
			}

			const self = debug;

			// Set `diff` timestamp
			const curr = Number(new Date());
			const ms = curr - (prevTime || curr);
			self.diff = ms;
			self.prev = prevTime;
			self.curr = curr;
			prevTime = curr;

			args[0] = createDebug.coerce(args[0]);

			if (typeof args[0] !== 'string') {
				// Anything else let's inspect with %O
				args.unshift('%O');
			}

			// Apply any `formatters` transformations
			let index = 0;
			args[0] = args[0].replace(/%([a-zA-Z%])/g, (match, format) => {
				// If we encounter an escaped % then don't increase the array index
				if (match === '%%') {
					return match;
				}
				index++;
				const formatter = createDebug.formatters[format];
				if (typeof formatter === 'function') {
					const val = args[index];
					match = formatter.call(self, val);

					// Now we need to remove `args[index]` since it's inlined in the `format`
					args.splice(index, 1);
					index--;
				}
				return match;
			});

			// Apply env-specific formatting (colors, etc.)
			createDebug.formatArgs.call(self, args);

			const logFn = self.log || createDebug.log;
			logFn.apply(self, args);
		}

		debug.namespace = namespace;
		debug.enabled = createDebug.enabled(namespace);
		debug.useColors = createDebug.useColors();
		debug.color = selectColor(namespace);
		debug.destroy = destroy;
		debug.extend = extend;
		// Debug.formatArgs = formatArgs;
		// debug.rawLog = rawLog;

		// env-specific initialization logic for debug instances
		if (typeof createDebug.init === 'function') {
			createDebug.init(debug);
		}

		createDebug.instances.push(debug);

		return debug;
	}

	function destroy() {
		const index = createDebug.instances.indexOf(this);
		if (index !== -1) {
			createDebug.instances.splice(index, 1);
			return true;
		}
		return false;
	}

	function extend(namespace, delimiter) {
		const newDebug = createDebug(this.namespace + (typeof delimiter === 'undefined' ? ':' : delimiter) + namespace);
		newDebug.log = this.log;
		return newDebug;
	}

	/**
	* Enables a debug mode by namespaces. This can include modes
	* separated by a colon and wildcards.
	*
	* @param {String} namespaces
	* @api public
	*/
	function enable(namespaces) {
		createDebug.save(namespaces);

		createDebug.names = [];
		createDebug.skips = [];

		let i;
		const split = (typeof namespaces === 'string' ? namespaces : '').split(/[\s,]+/);
		const len = split.length;

		for (i = 0; i < len; i++) {
			if (!split[i]) {
				// ignore empty strings
				continue;
			}

			namespaces = split[i].replace(/\*/g, '.*?');

			if (namespaces[0] === '-') {
				createDebug.skips.push(new RegExp('^' + namespaces.substr(1) + '$'));
			} else {
				createDebug.names.push(new RegExp('^' + namespaces + '$'));
			}
		}

		for (i = 0; i < createDebug.instances.length; i++) {
			const instance = createDebug.instances[i];
			instance.enabled = createDebug.enabled(instance.namespace);
		}
	}

	/**
	* Disable debug output.
	*
	* @return {String} namespaces
	* @api public
	*/
	function disable() {
		const namespaces = [
			...createDebug.names.map(toNamespace),
			...createDebug.skips.map(toNamespace).map(namespace => '-' + namespace)
		].join(',');
		createDebug.enable('');
		return namespaces;
	}

	/**
	* Returns true if the given mode name is enabled, false otherwise.
	*
	* @param {String} name
	* @return {Boolean}
	* @api public
	*/
	function enabled(name) {
		if (name[name.length - 1] === '*') {
			return true;
		}

		let i;
		let len;

		for (i = 0, len = createDebug.skips.length; i < len; i++) {
			if (createDebug.skips[i].test(name)) {
				return false;
			}
		}

		for (i = 0, len = createDebug.names.length; i < len; i++) {
			if (createDebug.names[i].test(name)) {
				return true;
			}
		}

		return false;
	}

	/**
	* Convert regexp to namespace
	*
	* @param {RegExp} regxep
	* @return {String} namespace
	* @api private
	*/
	function toNamespace(regexp) {
		return regexp.toString()
			.substring(2, regexp.toString().length - 2)
			.replace(/\.\*\?$/, '*');
	}

	/**
	* Coerce `val`.
	*
	* @param {Mixed} val
	* @return {Mixed}
	* @api private
	*/
	function coerce(val) {
		if (val instanceof Error) {
			return val.stack || val.message;
		}
		return val;
	}

	createDebug.enable(createDebug.load());

	return createDebug;
}

module.exports = setup;

},{"ms":21}],20:[function(_dereq_,module,exports){
/*!
  * domready (c) Dustin Diaz 2014 - License MIT
  */
!function (name, definition) {

  if (typeof module != 'undefined') module.exports = definition()
  else if (typeof define == 'function' && typeof define.amd == 'object') define(definition)
  else this[name] = definition()

}('domready', function () {

  var fns = [], listener
    , doc = document
    , hack = doc.documentElement.doScroll
    , domContentLoaded = 'DOMContentLoaded'
    , loaded = (hack ? /^loaded|^c/ : /^loaded|^i|^c/).test(doc.readyState)


  if (!loaded)
  doc.addEventListener(domContentLoaded, listener = function () {
    doc.removeEventListener(domContentLoaded, listener)
    loaded = 1
    while (listener = fns.shift()) listener()
  })

  return function (fn) {
    loaded ? setTimeout(fn, 0) : fns.push(fn)
  }

});

},{}],21:[function(_dereq_,module,exports){
/**
 * Helpers.
 */

var s = 1000;
var m = s * 60;
var h = m * 60;
var d = h * 24;
var w = d * 7;
var y = d * 365.25;

/**
 * Parse or format the given `val`.
 *
 * Options:
 *
 *  - `long` verbose formatting [false]
 *
 * @param {String|Number} val
 * @param {Object} [options]
 * @throws {Error} throw an error if val is not a non-empty string or a number
 * @return {String|Number}
 * @api public
 */

module.exports = function(val, options) {
  options = options || {};
  var type = typeof val;
  if (type === 'string' && val.length > 0) {
    return parse(val);
  } else if (type === 'number' && isFinite(val)) {
    return options.long ? fmtLong(val) : fmtShort(val);
  }
  throw new Error(
    'val is not a non-empty string or a valid number. val=' +
      JSON.stringify(val)
  );
};

/**
 * Parse the given `str` and return milliseconds.
 *
 * @param {String} str
 * @return {Number}
 * @api private
 */

function parse(str) {
  str = String(str);
  if (str.length > 100) {
    return;
  }
  var match = /^(-?(?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?|w|years?|yrs?|y)?$/i.exec(
    str
  );
  if (!match) {
    return;
  }
  var n = parseFloat(match[1]);
  var type = (match[2] || 'ms').toLowerCase();
  switch (type) {
    case 'years':
    case 'year':
    case 'yrs':
    case 'yr':
    case 'y':
      return n * y;
    case 'weeks':
    case 'week':
    case 'w':
      return n * w;
    case 'days':
    case 'day':
    case 'd':
      return n * d;
    case 'hours':
    case 'hour':
    case 'hrs':
    case 'hr':
    case 'h':
      return n * h;
    case 'minutes':
    case 'minute':
    case 'mins':
    case 'min':
    case 'm':
      return n * m;
    case 'seconds':
    case 'second':
    case 'secs':
    case 'sec':
    case 's':
      return n * s;
    case 'milliseconds':
    case 'millisecond':
    case 'msecs':
    case 'msec':
    case 'ms':
      return n;
    default:
      return undefined;
  }
}

/**
 * Short format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */

function fmtShort(ms) {
  var msAbs = Math.abs(ms);
  if (msAbs >= d) {
    return Math.round(ms / d) + 'd';
  }
  if (msAbs >= h) {
    return Math.round(ms / h) + 'h';
  }
  if (msAbs >= m) {
    return Math.round(ms / m) + 'm';
  }
  if (msAbs >= s) {
    return Math.round(ms / s) + 's';
  }
  return ms + 'ms';
}

/**
 * Long format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */

function fmtLong(ms) {
  var msAbs = Math.abs(ms);
  if (msAbs >= d) {
    return plural(ms, msAbs, d, 'day');
  }
  if (msAbs >= h) {
    return plural(ms, msAbs, h, 'hour');
  }
  if (msAbs >= m) {
    return plural(ms, msAbs, m, 'minute');
  }
  if (msAbs >= s) {
    return plural(ms, msAbs, s, 'second');
  }
  return ms + ' ms';
}

/**
 * Pluralization helper.
 */

function plural(ms, msAbs, n, name) {
  var isPlural = msAbs >= n * 1.5;
  return Math.round(ms / n) + ' ' + name + (isPlural ? 's' : '');
}

},{}],22:[function(_dereq_,module,exports){
// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };

},{}],23:[function(_dereq_,module,exports){
void function(root){

  function defaults(options){
    var options = options || {}
    var min = options.min
    var max = options.max
    var integer = options.integer || false
    if ( min == null && max == null ) {
      min = 0
      max = 1
    } else if ( min == null ) {
      min = max - 1
    } else if ( max == null ) {
      max = min + 1
    }
    if ( max < min ) throw new Error('invalid options, max must be >= min')
    return {
      min:     min
    , max:     max
    , integer: integer
    }
  }

  function random(options){
    options = defaults(options)
    if ( options.max === options.min ) return options.min
    var r = Math.random() * (options.max - options.min + Number(!!options.integer)) + options.min
    return options.integer ? Math.floor(r) : r
  }

  function generator(options){
    options = defaults(options)
    return function(min, max, integer){
      options.min     = min != null ? min : options.min
      options.max     = max != null ? max : options.max
      options.integer = integer != null ? integer : options.integer
      return random(options)
    }
  }

  module.exports =  random
  module.exports.generator = generator
  module.exports.defaults = defaults
}(this)

},{}],24:[function(_dereq_,module,exports){
module.exports =
{
	EventTarget : _dereq_('./lib/EventTarget'),
	Event       : _dereq_('./lib/Event')
};

},{"./lib/Event":25,"./lib/EventTarget":26}],25:[function(_dereq_,module,exports){
(function (global){
/**
 * In browsers export the native Event interface.
 */

module.exports = global.Event;

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{}],26:[function(_dereq_,module,exports){
function yaetiEventTarget()
{
	this._listeners = {};
}

Object.defineProperties(yaetiEventTarget.prototype,
	{
		listeners:
		{
			get: function()
			{
				return this._listeners;
			}
		}
	});

yaetiEventTarget.prototype.addEventListener = function(type, newListener)
{
	var listenersType;
	var i;
	var listener;

	if (!type || !newListener)
		return;

	listenersType = this._listeners[type];

	if (listenersType === undefined)
		this._listeners[type] = listenersType = [];

	for (i = 0; !!(listener = listenersType[i]); i++)
	{
		if (listener === newListener)
			return;
	}

	listenersType.push(newListener);
};

yaetiEventTarget.prototype.removeEventListener = function(type, oldListener)
{
	var listenersType;
	var i;
	var listener;

	if (!type || !oldListener)
		return;

	listenersType = this._listeners[type];

	if (listenersType === undefined)
		return;

	for (i = 0; !!(listener = listenersType[i]); i++)
	{
		if (listener === oldListener)
		{
			listenersType.splice(i, 1);
			break;
		}
	}

	if (listenersType.length === 0)
		delete this._listeners[type];
};

yaetiEventTarget.prototype.dispatchEvent = function(event)
{
	var type;
	var listenersType;
	var dummyListener;
	var stopImmediatePropagation = false;
	var i;
	var listener;

	if (!event || typeof event.type !== 'string')
		throw new Error('`event` must have a valid `type` property');

	// Do some stuff to emulate DOM Event behavior (just if this is not a
	// DOM Event object).
	if (event._yaeti)
	{
		event.target = this;
		event.cancelable = true;
	}

	// Attempt to override the stopImmediatePropagation() method.
	try
	{
		event.stopImmediatePropagation = function()
		{
			stopImmediatePropagation = true;
		};
	}
	catch (error)
	{}

	type = event.type;
	listenersType = (this._listeners[type] || []);

	dummyListener = this['on' + type];

	if (typeof dummyListener === 'function')
	{
		try
		{
			dummyListener.call(this, event);
		}
		catch (error)
		{
			console.error(error);
		}
	}

	for (i = 0; !!(listener = listenersType[i]); i++)
	{
		if (stopImmediatePropagation)
			break;

		try
		{
			listener.call(this, event);
		}
		catch (error)
		{
			console.error(error);
		}
	}

	return !event.defaultPrevented;
};

module.exports = yaetiEventTarget;

},{}]},{},[16])(16)
});
