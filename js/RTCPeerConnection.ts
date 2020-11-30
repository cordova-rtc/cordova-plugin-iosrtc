import debugBase from 'debug';
import { RTCRtpReceiverShim } from './RTCRtpReceiver';
import { RTCRtpSenderShim } from './RTCRtpSender';
import { RTCRtpTransceiverShim } from './RTCRtpTransceiver';
import { EventTargetShim } from './EventTarget';
import { RTCSessionDescriptionShim, RTCSessionDescriptionAsJSON } from './RTCSessionDescription';
import { RTCIceCandidateShim } from './RTCIceCandidate';
import { RTCDataChannelShim, RTCDataChannelAsJSON } from './RTCDataChannel';
import { RTCDTMFSenderShim } from './RTCDTMFSender';
import { RTCStatsReportShim } from './RTCStatsReport';
import { RTCStatsShim, RTCStatsAsJSON } from './RTCStats';
import {
	createMediaStream,
	MediaStreamShim,
	MediaStreamAsJSON,
	originalMediaStream
} from './MediaStream';
import { MediaStreamTrackShim, MediaStreamTrackAsJSON } from './MediaStreamTrack';
import { detectDeprecatedCallbaksUsage, Errors } from './Errors';
import { randomNumber } from './randomNumber';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:RTCPeerConnection'),
	debugerror = require('debug')('iosrtc:ERROR:RTCPeerConnection');
debugerror.log = console.warn.bind(console);

interface AddStreamEvent {
	type: 'addstream';
	streamId: string;
	stream: MediaStreamAsJSON;
}

interface RemoveStreamEvent {
	type: 'removestream';
	streamId: string;
}

interface TrackEvent {
	type: 'track';
	track: MediaStreamTrackAsJSON;
}

interface TrackWithStreamEvent {
	type: 'track';
	track: MediaStreamTrackAsJSON;
	streamId: string;
	stream: MediaStreamAsJSON;
}

interface SignalingStateChangeEvent {
	type: 'signalingstatechange';
	signalingState: RTCSignalingState;
}

interface NegotiationNeededEvent {
	type: 'negotiationneeded';
}

interface IceConnectionStateChangeEvent {
	type: 'iceconnectionstatechange';
	iceConnectionState: RTCIceConnectionState;
}

interface IceGatheringStateChangeEvent {
	type: 'icegatheringstatechange';
	iceGatheringState: RTCIceGatheringState;
}

interface EmptyIceCandidateEvent {
	type: 'icecandidate';
	// NOTE: in swift, cannot set null as value.
	candidate: false;
	localDescription: RTCSessionDescriptionAsJSON;
}
interface IceCandidateEvent {
	type: 'icecandidate';
	candidate: RTCIceCandidateInit;
	localDescription: RTCSessionDescriptionAsJSON;
}

interface DataChannelEvent {
	type: 'datachannel';
	channel: RTCDataChannelAsJSON;
}

type PeerConnectionEvent =
	| AddStreamEvent
	| RemoveStreamEvent
	| TrackEvent
	| TrackWithStreamEvent
	| SignalingStateChangeEvent
	| NegotiationNeededEvent
	| IceConnectionStateChangeEvent
	| IceGatheringStateChangeEvent
	| EmptyIceCandidateEvent
	| IceCandidateEvent
	| DataChannelEvent;

interface PeerConnectionConstraints {
	mandatory?: unknown;
	optional?: {
		DtlsSrtpKeyAgreement?: boolean;
		googIPv6?: boolean;
		googImprovedWifiBwe?: boolean;
		googDscp?: boolean;
		googCpuOveruseDetection?: boolean;
		googCpuUnderuseThreshold?: number;
		googCpuOveruseThreshold?: number;
		googSuspendBelowMinBitrate?: boolean;
	};
}

function deprecateWarning(method: string, newMethod: string) {
	if (!newMethod) {
		console.warn(method + ' is deprecated.');
	} else {
		console.warn(method + ' method is deprecated, use ' + newMethod + ' instead.');
	}
}

export class RTCPeerConnectionShim extends EventTargetShim implements RTCPeerConnection {
	readonly pcId = randomNumber();

	_localDescription: RTCSessionDescriptionShim | null = null;
	remoteDescription: RTCSessionDescriptionShim | null = null;
	signalingState: RTCSignalingState = 'stable';
	iceGatheringState: RTCIceGatheringState = 'new';
	iceConnectionState: RTCIceConnectionState = 'new';

	private localStreams: { [id: string]: MediaStreamShim } = {};
	private remoteStreams: { [id: string]: MediaStreamShim } = {};
	private localTracks: { [id: string]: MediaStreamTrackShim } = {};
	private remoteTracks: { [id: string]: MediaStreamTrackShim } = {};

	constructor(private pcConfig: RTCConfiguration, pcConstraints?: PeerConnectionConstraints) {
		super();
		debug('new() | [pcConfig:%o, pcConstraints:%o]', pcConfig, pcConstraints);

		// Restore corrupted RTCPeerConnection.prototype
		// TODO find why webrtc-adapter prevent events onnegotiationneeded to be trigger.
		// Object.defineProperties(this, RTCPeerConnection.prototype_descriptor);

		// Fix webrtc-adapter bad SHIM on addTrack causing error when original does support multiple streams.
		// NotSupportedError: The adapter.js addTrack, addStream polyfill only supports a single stream which is associated with the specified track.
		Object.defineProperty(
			this,
			'addTrack',
			(RTCPeerConnectionShim as any).prototype_descriptor.addTrack
		);
		Object.defineProperty(
			this,
			'addStream',
			(RTCPeerConnectionShim as any).prototype_descriptor.addStream
		);
		Object.defineProperty(
			this,
			'getLocalStreams',
			(RTCPeerConnectionShim as any).prototype_descriptor.getLocalStreams
		);

		const onResultOK = (data: PeerConnectionEvent) => this.onEvent(data);
		exec(onResultOK, null, 'iosrtcPlugin', 'new_RTCPeerConnection', [
			this.pcId,
			this.pcConfig,
			pcConstraints
		]);
	}

	get localDescription() {
		return this._localDescription;
	}
	get connectionState(): RTCPeerConnectionState {
		if (this.isClosed()) {
			return 'closed';
		}

		switch (this.iceConnectionState) {
			case 'checking':
				return 'connecting';
			case 'completed':
				return 'connected';
		}

		return this.iceConnectionState;
	}
	set onicecandidate(callback: (this: RTCPeerConnection, ev: RTCPeerConnectionIceEvent) => any) {
		this.addEventListener('icecandidate', callback as EventListener);
	}
	set onaddstream(callback: (this: RTCPeerConnection, ev: RTCPeerConnectionIceEvent) => any) {
		this.addEventListener('addstream', callback as EventListener);
	}
	set ontrack(callback: (this: RTCPeerConnection, ev: RTCTrackEvent) => any) {
		this.addEventListener('track', callback as EventListener);
	}
	set oniceconnectionstatechange(callback: (this: RTCPeerConnection, ev: Event) => any) {
		this.addEventListener('iceconnectionstatechange', callback);
	}
	set onnegotiationneeded(callback: (this: RTCPeerConnection, ev: Event) => any) {
		this.addEventListener('negotiationneeded', callback);
	}

	createOffer(options: RTCOfferOptions): Promise<RTCSessionDescriptionShim> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		// eslint-disable-next-line prefer-rest-params
		detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createOffer', arguments);

		if (this.isClosed()) {
			return Promise.reject();
		}

		debug('createOffer() [options:%o]', options);

		return new Promise((resolve, reject) => {
			const onResultOK = (data: RTCSessionDescriptionAsJSON) => {
					if (this.isClosed()) {
						return;
					}

					const desc = new RTCSessionDescriptionShim(data);

					debug('createOffer() | success [desc:%o]', desc);
					resolve(desc);
				},
				onResultError = (error: string) => {
					if (this.isClosed()) {
						return;
					}

					debugerror('createOffer() | failure: %s', error);
					reject(new global.DOMException(error));
				};

			exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createOffer', [
				this.pcId,
				options
			]);
		});
	}

	createAnswer(options: RTCAnswerOptions): Promise<RTCSessionDescriptionShim> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		// eslint-disable-next-line prefer-rest-params
		detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.createAnswer', arguments);

		if (this.isClosed()) {
			return Promise.reject();
		}

		debug('createAnswer() [options:%o]', options);

		return new Promise((resolve, reject) => {
			const onResultOK = (data: RTCSessionDescriptionAsJSON) => {
					if (this.isClosed()) {
						return;
					}

					const desc = new RTCSessionDescriptionShim(data);

					debug('createAnswer() | success [desc:%o]', desc);
					resolve(desc);
				},
				onResultError = (error: string) => {
					if (this.isClosed()) {
						return;
					}

					debugerror('createAnswer() | failure: %s', error);
					reject(new global.DOMException(error));
				};

			exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_createAnswer', [
				this.pcId,
				options
			]);
		});
	}

	setLocalDescription(desc: RTCSessionDescriptionShim): Promise<void> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		// eslint-disable-next-line prefer-rest-params
		detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.setLocalDescription', arguments);

		if (this.isClosed()) {
			return new Promise((resolve, reject) => {
				reject(new Errors.InvalidStateError('peerconnection is closed'));
			});
		}

		// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other
		// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary,
		// so you don't have to instantiate an RTCSessionDescription yourself.""
		// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
		// Still we do instnanciate RTCSessionDescription, so internal object is used properly.

		if (!(desc instanceof RTCSessionDescriptionShim)) {
			desc = new RTCSessionDescriptionShim(desc);
		}

		return new Promise((resolve, reject) => {
			const onResultOK = (data: RTCSessionDescriptionAsJSON) => {
					if (this.isClosed()) {
						return;
					}

					debug('setLocalDescription() | success');
					// Update localDescription.
					this._localDescription = new RTCSessionDescriptionShim(data);
					resolve();
				},
				onResultError = (error: string) => {
					if (this.isClosed()) {
						return;
					}

					debugerror('setLocalDescription() | failure: %s', error);
					reject(
						new Errors.InvalidSessionDescriptionError(
							'setLocalDescription() failed: ' + error
						)
					);
				};

			exec(
				onResultOK,
				onResultError,
				'iosrtcPlugin',
				'RTCPeerConnection_setLocalDescription',
				[this.pcId, desc]
			);
		});
	}

	setRemoteDescription(desc: RTCSessionDescriptionShim): Promise<void> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		detectDeprecatedCallbaksUsage(
			'RTCPeerConnection.prototype.setRemoteDescription',
			// eslint-disable-next-line prefer-rest-params
			arguments
		);

		if (this.isClosed()) {
			return new Promise((resolve, reject) => {
				reject(new Errors.InvalidStateError('peerconnection is closed'));
			});
		}

		debug('setRemoteDescription() [desc:%o]', desc);

		// "This is no longer necessary, however; RTCPeerConnection.setLocalDescription() and other
		// methods which take SDP as input now directly accept an object conforming to the RTCSessionDescriptionInit dictionary,
		// so you don't have to instantiate an RTCSessionDescription yourself.""
		// Source: https://developer.mozilla.org/en-US/docs/Web/API/RTCSessionDescription/RTCSessionDescription#Example
		// Still we do instnanciate RTCSessionDescription so internal object is used properly.

		if (!(desc instanceof RTCSessionDescriptionShim)) {
			desc = new RTCSessionDescriptionShim(desc);
		}

		return new Promise((resolve, reject) => {
			const onResultOK = (data: RTCSessionDescriptionAsJSON) => {
					if (this.isClosed()) {
						return;
					}

					debug('setRemoteDescription() | success');
					// Update remoteDescription.
					this.remoteDescription = new RTCSessionDescriptionShim(data);
					resolve();
				},
				onResultError = (error: string) => {
					if (this.isClosed()) {
						return;
					}

					debugerror('setRemoteDescription() | failure: %s', error);
					reject(
						new Errors.InvalidSessionDescriptionError(
							'setRemoteDescription() failed: ' + error
						)
					);
				};

			exec(
				onResultOK,
				onResultError,
				'iosrtcPlugin',
				'RTCPeerConnection_setRemoteDescription',
				[this.pcId, desc]
			);
		});
	}

	addIceCandidate(candidate: RTCIceCandidateShim): Promise<void> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		// eslint-disable-next-line prefer-rest-params
		detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.addIceCandidate', arguments);

		if (this.isClosed()) {
			return new Promise((resolve, reject) => {
				reject(new Errors.InvalidStateError('peerconnection is closed'));
			});
		}

		debug('addIceCandidate() | [candidate:%o]', candidate);

		if (typeof candidate !== 'object') {
			return new Promise((resolve, reject) => {
				reject(
					new global.DOMException(
						'addIceCandidate() must be called with a RTCIceCandidate instance or RTCIceCandidateInit object as argument'
					)
				);
			});
		}

		return new Promise((resolve, reject) => {
			const onResultOK = (data: {
					remoteDescription: RTCSessionDescriptionAsJSON | false;
				}) => {
					if (this.isClosed()) {
						return;
					}

					debug('addIceCandidate() | success');
					// Update remoteDescription.
					if (this.remoteDescription && data.remoteDescription) {
						this.remoteDescription.type = data.remoteDescription.type;
						this.remoteDescription.sdp = data.remoteDescription.sdp;
					} else if (data.remoteDescription) {
						this.remoteDescription = new RTCSessionDescriptionShim(
							data.remoteDescription
						);
					}
					resolve();
				},
				onResultError = () => {
					if (this.isClosed()) {
						return;
					}

					debugerror('addIceCandidate() | failure');
					reject(new global.DOMException('addIceCandidate() failed'));
				};

			exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_addIceCandidate', [
				this.pcId,
				candidate
			]);
		});
	}

	getLocalStreams() {
		debug('getLocalStreams()');
		deprecateWarning('getLocalStreams', 'getSenders');
		return Object.values(this.localStreams);
	}

	getRemoteStreams() {
		debug('getRemoteStreams()');
		deprecateWarning('getRemoteStreams', 'getReceivers');
		return Object.values(this.remoteStreams);
	}

	getReceivers() {
		return Object.values(this.remoteTracks).map((track) => {
			return new RTCRtpReceiverShim({
				pc: this,
				track: track
			});
		});
	}

	getSenders() {
		return Object.values(this.localTracks).map((track) => {
			return new RTCRtpSenderShim({
				pc: this,
				track: track,
				params: {} as RTCRtpSendParameters
			});
		});
	}

	getTransceivers() {
		return [
			...this.getReceivers().map((receiver) => {
				return new RTCRtpTransceiverShim({ receiver });
			}),
			...this.getSenders().map((sender) => {
				return new RTCRtpTransceiverShim({ sender });
			})
		];
	}

	addTrack(track: MediaStreamTrackShim, ...streams: MediaStreamShim[]) {
		let stream: MediaStreamShim | undefined = streams[0];

		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		// Add localStreams if missing
		// Disable to match browser behavior
		//stream = stream || Object.values(this.localStreams)[0] || new MediaStream();

		// Fix webrtc-adapter bad SHIM on addStream
		if (stream) {
			this.addStream(stream);
		}

		for (const id in this.localStreams) {
			if (this.localStreams.hasOwnProperty(id)) {
				// Target provided stream argument or first added stream to group track
				if (!stream || (stream && stream.id === id)) {
					stream = this.localStreams[id];
					stream.addTrack(track);
					exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [
						this.pcId,
						track.id,
						id
					]);
					break;
				}
			}
		}

		// No Stream matched add track without stream
		if (!stream) {
			exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addTrack', [
				this.pcId,
				track.id,
				null
			]);
		}

		this.localTracks[track.id] = track;

		return new RTCRtpSenderShim({
			pc: this,
			track: track,
			params: {} as RTCRtpSendParameters
		});
	}

	removeTrack(sender: RTCRtpSenderShim) {
		if (!(sender instanceof RTCRtpSenderShim)) {
			throw new Error(
				'removeTrack() must be called with a RTCRtpSender instance as argument'
			);
		}

		const track = sender.track;

		if (!track) {
			return;
		}

		const stream = Object.values(this.localStreams).find((localStream) => {
			localStream.getTracks().some((localTrack) => localTrack.id === track.id);
		});

		stream?.removeTrack(track);
		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeTrack', [
			this.pcId,
			track.id,
			stream?.id ?? null
		]);

		delete this.localTracks[track.id];
	}

	getStreamById(id: string) {
		debug('getStreamById()');

		return this.localStreams[id] || this.remoteStreams[id] || null;
	}

	addStream(stream: MediaStreamShim) {
		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		debug('addStream()');

		if (!(stream instanceof originalMediaStream)) {
			throw new Error('addStream() must be called with a MediaStream instance as argument');
		}

		if (this.localStreams[stream.id]) {
			debugerror('addStream() | given stream already in present in local streams');
			return;
		}

		this.localStreams[stream.id] = stream;

		stream.addedToConnection = true;

		stream.getTracks().forEach((track) => {
			this.localTracks[track.id] = track;
			track.addEventListener('ended', () => {
				delete this.localTracks[track.id];
			});
		});

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_addStream', [this.pcId, stream.id]);
	}

	removeStream(stream: MediaStreamShim) {
		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		debug('removeStream()');

		if (!(stream instanceof originalMediaStream)) {
			throw new Error(
				'removeStream() must be called with a MediaStream instance as argument'
			);
		}

		if (!this.localStreams[stream.id]) {
			debugerror('removeStream() | given stream not present in local streams');
			return;
		}

		delete this.localStreams[stream.id];

		stream.getTracks().forEach((track) => {
			delete this.localTracks[track.id];
		});

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_removeStream', [this.pcId, stream.id]);
	}

	createDataChannel(label: string, options: RTCDataChannelInit) {
		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		debug('createDataChannel() [label:%s, options:%o]', label, options);

		return new RTCDataChannelShim(this, label, options);
	}

	createDTMFSender(track: MediaStreamTrackShim) {
		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		debug('createDTMFSender() [track:%o]', track);

		return new RTCDTMFSenderShim(this, track);
	}

	getStats(selector?: MediaStreamTrackShim | null): Promise<RTCStatsReport> {
		// Detect callback usage to assist 5.0.1 to 5.0.2 migration
		// TODO remove on 6.0.0
		// eslint-disable-next-line prefer-rest-params
		detectDeprecatedCallbaksUsage('RTCPeerConnection.prototype.getStats', arguments);

		if (selector && !(selector instanceof MediaStreamTrackShim)) {
			throw new Error(
				'getStats() must be called with null or a valid MediaStreamTrack instance as argument'
			);
		}

		if (this.isClosed()) {
			throw new Errors.InvalidStateError('peerconnection is closed');
		}

		// debug('getStats() [selector:%o]', selector);

		return new Promise((resolve, reject) => {
			const onResultOK = (array: RTCStatsAsJSON[]) => {
					if (this.isClosed()) {
						return;
					}

					const stats = array.map((reportData) => new RTCStatsShim(reportData));
					// TODO: this should resolve with a single Report, rather than a multi report Response
					resolve(new RTCStatsReportShim(stats));
				},
				onResultError = (error: string) => {
					if (this.isClosed()) {
						return;
					}

					debugerror('getStats() | failure: %s', error);
					reject(new global.DOMException(error));
				};

			exec(onResultOK, onResultError, 'iosrtcPlugin', 'RTCPeerConnection_getStats', [
				this.pcId,
				selector ? selector.id : null
			]);
		});
	}

	close() {
		if (this.isClosed()) {
			return;
		}

		debug('close()');

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_close', [this.pcId]);
	}

	getConfiguration() {
		return this.pcConfig;
	}

	isClosed() {
		return this.signalingState === 'closed';
	}

	onEvent(data: PeerConnectionEvent) {
		const type = data.type,
			event = new Event(type);

		Object.defineProperty(event, 'target', { value: this, enumerable: true });

		debug('onEvent() | [type:%s, data:%o]', type, data);

		switch (data.type) {
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
					Object.values(this.remoteStreams).forEach((stream) => stream.emitConnected());
				}
				break;

			case 'icecandidate':
				if (data.candidate) {
					(event as any).candidate = new RTCIceCandidateShim(data.candidate);
				} else {
					(event as any).candidate = null;
				}
				// Update _localDescription.
				if (this._localDescription && data.localDescription) {
					this._localDescription.type = data.localDescription.type;
					this._localDescription.sdp = data.localDescription.sdp;
				} else if (data.localDescription) {
					this._localDescription = new RTCSessionDescriptionShim(data.localDescription);
				}
				break;

			case 'negotiationneeded':
				break;

			case 'track':
				const track = new MediaStreamTrackShim(data.track),
					receiver = new RTCRtpReceiverShim({ pc: this, track }),
					streams: MediaStreamShim[] = [];
				(event as any).track = track;
				(event as any).receiver = receiver;
				(event as any).transceiver = new RTCRtpTransceiverShim({ receiver });
				(event as any).streams = streams;

				// Add stream only if available in case of Unified-Plan of track event without stream
				if ('stream' in data && 'streamId' in data) {
					const stream =
						this.remoteStreams[data.streamId] || createMediaStream(data.stream);
					streams.push(stream);
				}

				// Store remote track
				this.remoteTracks[track.id] = track;
				track.addEventListener('ended', () => {
					delete this.remoteTracks[track.id];
				});

				break;

			case 'addstream':
				// Append to the remote streams.
				const stream = (this.remoteStreams[data.streamId] =
					this.remoteStreams[data.streamId] || createMediaStream(data.stream));

				(event as any).stream = stream;

				// Emit "connected" on the stream if ICE connected.
				if (
					this.iceConnectionState === 'connected' ||
					this.iceConnectionState === 'completed'
				) {
					stream.emitConnected();
				}
				break;

			case 'removestream':
				(event as any).stream = this.remoteStreams[data.streamId];

				// Remove from the remote streams.
				delete this.remoteStreams[data.streamId];
				break;

			case 'datachannel':
				const dataChannel = new RTCDataChannelShim(this, null, null, data.channel);
				(event as any).channel = dataChannel;
				break;
		}

		this.dispatchEvent(event);
	}

	/**
	 * Additional events listeners
	 */
	onconnectionstatechange = null;
	ondatachannel = null;
	onicecandidateerror = null;
	onicegatheringstatechange = null;
	onsignalingstatechange = null;
	onstatsended = null;

	/**
	 * Additional, unimplemented members
	 */
	readonly canTrickleIceCandidates = null;
	readonly currentLocalDescription = null;
	readonly currentRemoteDescription = null;
	readonly idpErrorInfo = null;
	readonly idpLoginUrl = null;
	readonly peerIdentity = new Promise<RTCIdentityAssertion>(() => {
		// don't return an identity since we don't actually have it
	});
	readonly pendingLocalDescription = null;
	readonly pendingRemoteDescription = null;
	readonly sctp = null;

	addTransceiver(
		trackOrKind: MediaStreamTrackShim | string,
		init?: RTCRtpTransceiverInit
	): RTCRtpTransceiverShim {
		void trackOrKind;
		void init;
		throw new Error('RTCPeerConnection.addTransceiver not implemented');
	}
	getIdentityAssertion(): Promise<string> {
		return Promise.resolve('');
	}
	setConfiguration(configuration: RTCConfiguration): void {
		void configuration;
		throw new Error('RTCPeerConnection.setConfiguration not implemented');
	}
	setIdentityProvider(provider: string, options?: RTCIdentityProviderOptions): void {
		void provider;
		void options;
		throw new Error('RTCPeerConnection.setIdentityProvider not implemented');
	}
	generateCertificate(keygenAlgorithm: AlgorithmIdentifier): Promise<RTCCertificate> {
		void keygenAlgorithm;
		throw new Error('RTCPeerConnection.generateCertificate not implemented');
	}
	getDefaultIceServers(): RTCIceServer[] {
		throw new Error('RTCPeerConnection.getDefaultIceServers not implemented');
	}
}

// Save current RTCPeerConnection.prototype
(RTCPeerConnectionShim as any).prototype_descriptor = Object.getOwnPropertyDescriptors(
	RTCPeerConnectionShim.prototype
);
