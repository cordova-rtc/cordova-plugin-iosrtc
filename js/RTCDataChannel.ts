import debugBase from 'debug';
import { EventTargetShim } from './EventTarget';
import { RTCPeerConnectionShim } from './RTCPeerConnection';
import { randomNumber } from './randomNumber';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:RTCDataChannel'),
	debugerror = debugBase('iosrtc:ERROR:RTCDataChannel');
debugerror.log = console.warn.bind(console);

export type RTCDataChannelAsJSON = { dcId: number } & Pick<
	RTCDataChannel,
	| 'label'
	| 'ordered'
	| 'maxPacketLifeTime'
	| 'maxRetransmits'
	| 'protocol'
	| 'negotiated'
	| 'id'
	| 'readyState'
	| 'bufferedAmount'
>;

interface StateChangeEvent {
	type: 'statechange';
	readyState: RTCDataChannelState;
}

interface NewChannelEvent {
	type: 'new';
	channel: {
		ordered: boolean;
		maxPacketLifeTime: number | null;
		maxRetransmits: number | null;
		protocol: string;
		negotiated: boolean;
		id: number | null;
		readyState: RTCDataChannelState;
		bufferedAmount: number;
	};
}

interface BufferedAmountEvent {
	type: 'bufferedamount';
	bufferedAmount: number;
}

interface MessageEvent {
	type: 'message';
	message: string;
}

type BinaryMessage = ArrayBuffer;

type RTCDataChannelUpdateEvent =
	| StateChangeEvent
	| NewChannelEvent
	| BufferedAmountEvent
	| MessageEvent;

export class RTCDataChannelShim extends EventTargetShim implements RTCDataChannel {
	label: string;
	bufferedAmount: number;
	bufferedAmountLowThreshold = 0;
	id: number | null;
	maxPacketLifeTime: number | null;
	maxRetransmits: number | null;
	negotiated: boolean;
	ordered: boolean;
	protocol: string;
	readyState: RTCDataChannelState;
	dcId: number;

	constructor(
		private peerConnection: RTCPeerConnectionShim,
		label: string | null,
		options: Partial<RTCDataChannel> | null,
		dataFromEvent?: RTCDataChannelAsJSON
	) {
		super();

		const onResultOK = (data: RTCDataChannelUpdateEvent | BinaryMessage) => {
			if ('type' in data) {
				this.onEvent(data);
			} else {
				// Special handler for received binary message.
				this.onEvent({
					type: 'message',
					message: data
				});
			}
		};

		// Created via pc.createDataChannel().
		if (!dataFromEvent) {
			debug('new() | [label:%o, options:%o]', label, options);

			if (typeof label !== 'string') {
				label = '';
			}

			options = options || {};

			if (
				options.hasOwnProperty('maxPacketLifeTime') &&
				options.hasOwnProperty('maxRetransmits')
			) {
				throw new SyntaxError(
					'both maxPacketLifeTime and maxRetransmits can not be present'
				);
			}

			if (options.hasOwnProperty('id')) {
				if (typeof options.id !== 'number' || isNaN(options.id) || options.id < 0) {
					throw new SyntaxError('id must be a number');
				}
				// TODO:
				//   https://code.google.com/p/webrtc/issues/detail?id=4618
				if (options.id > 1023) {
					throw new SyntaxError(
						'id cannot be greater than 1023 (https://code.google.com/p/webrtc/issues/detail?id=4614)'
					);
				}
			}

			this.label = label;
			this.ordered = options.hasOwnProperty('ordered') ? !!options.ordered : true;
			this.maxPacketLifeTime = options.hasOwnProperty('maxPacketLifeTime')
				? Number(options.maxPacketLifeTime)
				: null;
			this.maxRetransmits = options.hasOwnProperty('maxRetransmits')
				? Number(options.maxRetransmits)
				: null;
			this.protocol = options.hasOwnProperty('protocol') ? String(options.protocol) : '';
			this.negotiated = options.hasOwnProperty('negotiated') ? !!options.negotiated : false;
			this.id = options.hasOwnProperty('id') ? Number(options.id) : null;
			this.readyState = 'connecting';
			this.bufferedAmount = 0;
			this.dcId = randomNumber();

			exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_createDataChannel', [
				this.peerConnection.pcId,
				this.dcId,
				label,
				options
			]);
		} else {
			// Created via pc.ondatachannel.
			debug('new() | [dataFromEvent:%o]', dataFromEvent);

			this.label = dataFromEvent.label;
			this.ordered = dataFromEvent.ordered;
			this.maxPacketLifeTime = dataFromEvent.maxPacketLifeTime;
			this.maxRetransmits = dataFromEvent.maxRetransmits;
			this.protocol = dataFromEvent.protocol;
			this.negotiated = dataFromEvent.negotiated;
			this.id = dataFromEvent.id;
			this.readyState = dataFromEvent.readyState;
			this.bufferedAmount = dataFromEvent.bufferedAmount;
			this.dcId = dataFromEvent.dcId;

			exec(onResultOK, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_setListener', [
				this.peerConnection.pcId,
				this.dcId
			]);
		}
	}

	// Just 'arraybuffer' binaryType is implemented in Chromium.
	get binaryType() {
		return 'arraybuffer';
	}
	set binaryType(type) {
		if (type !== 'arraybuffer') {
			throw new Error('just "arraybuffer" is implemented for binaryType');
		}
	}

	send = (data: string | Blob | ArrayBuffer | ArrayBufferView) => {
		if (this.isClosed() || this.readyState !== 'open') {
			return;
		}

		debug('send() | [data:%o]', data);

		if (!data) {
			return;
		}

		if (typeof data === 'string' || data instanceof String) {
			exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendString', [
				this.peerConnection.pcId,
				this.dcId,
				data
			]);
		} else if (window.ArrayBuffer && data instanceof window.ArrayBuffer) {
			exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [
				this.peerConnection.pcId,
				this.dcId,
				data
			]);
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
			exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_sendBinary', [
				this.peerConnection.pcId,
				this.dcId,
				data.buffer
			]);
		} else {
			throw new Error('invalid data type');
		}
	};

	close() {
		if (this.isClosed()) {
			return;
		}

		debug('close()');

		this.readyState = 'closing';

		exec(null, null, 'iosrtcPlugin', 'RTCPeerConnection_RTCDataChannel_close', [
			this.peerConnection.pcId,
			this.dcId
		]);
	}

	private isClosed() {
		return (
			this.readyState === 'closed' ||
			this.readyState === 'closing' ||
			this.peerConnection.signalingState === 'closed'
		);
	}

	private onEvent(data: RTCDataChannelUpdateEvent | { type: 'message'; message: ArrayBuffer }) {
		const type = data.type;

		debug('onEvent() | [type:%s, data:%o]', type, data);

		switch (data.type) {
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
				const event = new Event('message');
				(event as any).data = data.message;
				this.dispatchEvent(event);
				break;

			case 'bufferedamount':
				this.bufferedAmount = data.bufferedAmount;

				if (
					this.bufferedAmountLowThreshold > 0 &&
					this.bufferedAmountLowThreshold > this.bufferedAmount
				) {
					const event = new Event('bufferedamountlow');
					(event as any).bufferedAmount = this.bufferedAmount;
					this.dispatchEvent(event);
				}

				break;
		}
	}

	/**
	 * Additional, unimplemented members
	 */
	readonly priority = 'medium'; // priority not implemented on swift side
	onbufferedamountlow = null;
	onclose = null;
	onerror = null;
	onmessage = null;
	onopen = null;
}
