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
	EventTarget = require('./EventTarget'),


/**
 * Local variables.
 */

	// Dictionary of MediaStreams (provided via setMediaStreams() class method).
	// - key: MediaStream blobId.
	// - value: MediaStream.
	mediaStreams;


/**
 * Class methods.
 */


MediaStream.setMediaStreams = function (_mediaStreams) {
	mediaStreams = _mediaStreams;
};


MediaStream.create = function (dataFromEvent) {
	debug('create() | [dataFromEvent:%o]', dataFromEvent);

	var stream,
		blobId = 'MediaStream_' + dataFromEvent.id,
		trackId,
		track;

	// Note that this is the Blob constructor.
	stream = new MediaStream([blobId], {
		type: 'stream'
	});

	// Store the stream into the dictionary.
	mediaStreams[blobId] = stream;

	// Make it an EventTarget.
	EventTarget.call(stream);

	// Public atributes.
	stream.id = dataFromEvent.id;
	stream.label = dataFromEvent.id;  // Backwards compatibility.
	stream.active = true;

	// Private attributes.
	stream.blobId = blobId;
	stream.audioTracks = {};
	stream.videoTracks = {};
	stream.connected = false;

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

	function onResultOK(data) {
		onEvent.call(stream, data);
	}

	exec(onResultOK, null, 'iosrtcPlugin', 'MediaStream_setListener', [stream.id]);

	return stream;
};


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


MediaStream.prototype.emitConnected = function () {
	debug('emitConnected()');

	var self = this;

	if (this.connected) {
		return;
	}
	this.connected = true;

	setTimeout(function () {
		self.dispatchEvent(new Event('connected'));
	});
};


function addListenerForTrackEnded(track) {
	var self = this;

	track.addEventListener('ended', function () {
		if (track.kind === 'audio' && !self.audioTracks[track.id]) {
			return;
		} else if (track.kind === 'video' && !self.videoTracks[track.id]) {
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

	if (Object.keys(this.audioTracks).length === 0 && Object.keys(this.videoTracks).length === 0) {
		debug('no tracks, releasing MediaStream');

		release();
		return;
	}

	for (trackId in this.audioTracks) {
		if (this.audioTracks.hasOwnProperty(trackId)) {
			if (this.audioTracks[trackId].readyState !== 'ended') {
				return;
			}
		}
	}

	for (trackId in this.videoTracks) {
		if (this.videoTracks.hasOwnProperty(trackId)) {
			if (this.videoTracks[trackId].readyState !== 'ended') {
				return;
			}
		}
	}

	debug('all tracks are ended, releasing MediaStream');
	release();

	function release() {
		self.active = false;
		self.dispatchEvent(new Event('inactive'));

		// Remove the stream from the dictionary.
		delete mediaStreams[self.blobId];

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
				this.audioTracks[track.id] = track;
			} else if (track.kind === 'video') {
				this.videoTracks[track.id] = track;
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
				track = this.audioTracks[data.track.id];
				delete this.audioTracks[data.track.id];
			} else if (data.track.kind === 'video') {
				track = this.videoTracks[data.track.id];
				delete this.videoTracks[data.track.id];
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
