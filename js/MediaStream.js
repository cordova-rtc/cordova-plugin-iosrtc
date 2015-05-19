/**
 * Expose the MediaStream class.
 * Make MediaStream be a Blob so it can be consumed by URL.createObjectURL().
 */
var MediaStream = module.exports = window.Blob,


/**
 * Spec: http://w3c.github.io/mediacapture-main/#mediastream
 */


/**
 * Dependencies.
 */
	debug = require('debug')('iosrtc:MediaStream'),
	exec = require('cordova/exec'),
	MediaStreamTrack = require('./MediaStreamTrack'),
	EventTarget = require('./EventTarget');


/**
 * Class methods.
 */


MediaStream.create = function (dataFromEvent) {
	debug('create() | [dataFromEvent:%o]', dataFromEvent);

	var stream,
		trackId,
		track;

	// Note that this is the Blob constructor.
	stream = new MediaStream([dataFromEvent.id], {
		type: 'stream'
	});

	// Make it an EventTarget.
	EventTarget.call(stream);

	// Public atributes.
	stream.id = dataFromEvent.id;
	stream.label = dataFromEvent.id;  // Backwards compatibility.
	stream.active = true;

	// Private attributes.
	stream.audioTracks = {};
	stream.videoTracks = {};

	for (trackId in dataFromEvent.audioTracks) {
		if (dataFromEvent.audioTracks.hasOwnProperty(trackId)) {
			track = new MediaStreamTrack(dataFromEvent.audioTracks[trackId]);

			stream.audioTracks[track.id] = track;

			addListenerForTrackEnded.call(stream, track);
		}
	}

	for (trackId in dataFromEvent.videoTracks) {
		if (dataFromEvent.videoTracks.hasOwnProperty(trackId)) {
			track = new MediaStreamTrack(dataFromEvent.videoTracks[trackId]);

			stream.videoTracks[track.id] = track;

			addListenerForTrackEnded.call(stream, track);
		}
	}

	return stream;
};


// function MediaStream(dataFromEvent) {
// 	debug('new() | [dataFromEvent:%o]', dataFromEvent);

// 	var trackId,
// 		track;

// 	// Make this an EventTarget.
// 	EventTarget.call(this);

// 	// Public atributes.
// 	this.id = dataFromEvent.id;
// 	this.label = dataFromEvent.id;  // Backwards compatibility.
// 	this.active = true;  // TODO: No 'active' property in the RTCMediaStream ObjC class.

// 	// Private attributes.
// 	this.audioTracks = {};
// 	this.videoTracks = {};

// 	for (trackId in dataFromEvent.audioTracks) {
// 		if (dataFromEvent.audioTracks.hasOwnProperty(trackId)) {
// 			track = new MediaStreamTrack(dataFromEvent.audioTracks[trackId]);

// 			this.audioTracks[track.id] = track;
// 		}
// 	}

// 	for (trackId in dataFromEvent.videoTracks) {
// 		if (dataFromEvent.videoTracks.hasOwnProperty(trackId)) {
// 			track = new MediaStreamTrack(dataFromEvent.videoTracks[trackId]);

// 			this.videoTracks[track.id] = track;
// 		}
// 	}
// }


MediaStream.prototype.getAudioTracks = function () {
	debug('getAudioTracks()');

	var tracks = [],
		id;

	for (id in this.audioTracks) {
		if (this.audioTracks.hasOwnProperty(id)) {
			tracks.push(this.audioTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getVideoTracks = function () {
	debug('getVideoTracks()');

	var tracks = [],
		id;

	for (id in this.videoTracks) {
		if (this.videoTracks.hasOwnProperty(id)) {
			tracks.push(this.videoTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getTracks = function () {
	debug('getTracks()');

	var tracks = [],
		id;

	for (id in this.audioTracks) {
		if (this.audioTracks.hasOwnProperty(id)) {
			tracks.push(this.audioTracks[id]);
		}
	}

	for (id in this.videoTracks) {
		if (this.videoTracks.hasOwnProperty(id)) {
			tracks.push(this.videoTracks[id]);
		}
	}

	return tracks;
};


MediaStream.prototype.getTrackById = function (id) {
	debug('getTrackById()');

	return this.audioTracks[id] || this.videoTracks[id] || null;
};


MediaStream.prototype.addTrack = function (track) {
	debug('addTrack() [track:%o]', track);

	if (!(track instanceof MediaStreamTrack)) {
		throw new Error('argument must be an instance of MediaStreamTrack');
	}

	if (this.audioTracks[track.id] || this.videoTracks[track.id]) {
		return;
	}

	if (track.kind === 'audio') {
		this.audioTracks[track.id] = track;
	} else if (track.kind === 'video') {
		this.videoTracks[track.id] = track;
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

	if (!this.audioTracks[track.id] && !this.videoTracks[track.id]) {
		return;
	}

	if (track.kind === 'audio') {
		delete this.audioTracks[track.id];
	} else if (track.kind === 'video') {
		delete this.videoTracks[track.id];
	} else {
		throw new Error('unknown kind attribute: ' + track.kind);
	}

	exec(null, null, 'iosrtcPlugin', 'MediaStream_removeTrack', [this.id, track.id]);

	checkActive.call(this);
};


// Backwards compatible API.
MediaStream.prototype.stop = function () {
	debug('stop()');

	var trackId;

	for (trackId in this.audioTracks) {
		if (this.audioTracks.hasOwnProperty(trackId)) {
			this.audioTracks[trackId].stop();
		}
	}

	for (trackId in this.videoTracks) {
		if (this.videoTracks.hasOwnProperty(trackId)) {
			this.videoTracks[trackId].stop();
		}
	}
};


// TODO: API methods and events.


/**
 * Private API.
 */


function addListenerForTrackEnded(track) {
	var self = this;

	// NOTE: Theorically I shouldn't remove ended tracks, but I do.
	track.addEventListener('ended', function () {
		if (track.kind === 'audio' && self.audioTracks[track.id]) {
			delete self.audioTracks[track.id];
		} else if (track.kind === 'video' && self.videoTracks[track.id]) {
			delete self.videoTracks[track.id];
		}

		checkActive.call(self);
	});
}


function checkActive() {
	if (Object.keys(this.audioTracks).length === 0 && Object.keys(this.videoTracks).length === 0) {
		debug('no tracks in the MediaStream, releasing it');

		this.active = false;
		this.dispatchEvent(new Event('inactive'));

		exec(null, null, 'iosrtcPlugin', 'MediaStream_release', [this.id]);
	}
}
