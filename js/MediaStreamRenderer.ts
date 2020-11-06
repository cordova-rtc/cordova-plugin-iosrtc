import debugBase from 'debug';
import { EventTargetShim } from './EventTarget';
import { MediaStreamShim, originalMediaStream } from './MediaStream';
import { randomNumber } from './randomNumber';

const exec = require('cordova/exec'),
	debug = debugBase('iosrtc:MediaStreamRenderer');

// Dictionary of MediaStreamRenderers.
// - key: MediaStreamRenderer id.
// - value: MediaStreamRenderer.
export const mediaStreamRenderers: { [id: number]: MediaStreamRenderer } = {};

interface VideoResizeEvent {
	type: 'videoresize';
	size: {
		width: number;
		height: number;
	};
}

interface VideoStopEvent {
	type: 'videostop';
}

type MediaStreamRendererEvent = VideoResizeEvent | VideoStopEvent;

export class MediaStreamRenderer extends EventTargetShim {
	stream?: MediaStreamShim = undefined;
	videoWidth?: number = undefined;
	videoHeight?: number = undefined;

	id = randomNumber();

	constructor(public element: HTMLElement) {
		super();
		debug('new() | [element:"%s"]', element);

		if (!(element instanceof HTMLElement)) {
			throw new Error('a valid HTMLElement is required');
		}

		const onResultOK = (data: MediaStreamRendererEvent) => this.onEvent(data);
		exec(onResultOK, null, 'iosrtcPlugin', 'new_MediaStreamRenderer', [this.id]);

		this.refresh();

		// TODO cause video resizing jiggling add semaphore
		//this.refreshInterval = setInterval(function () {
		//	self.refresh(self);
		//}, 500);

		(element as any).render = this;
	}

	render(stream: MediaStreamShim) {
		debug('render() [stream:%o]', stream);

		if (!(stream instanceof originalMediaStream)) {
			throw new Error('render() requires a MediaStream instance as argument');
		}

		this.stream = stream;

		exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_render', [this.id, stream.id]);

		// Subscribe to 'update' event so we call native mediaStreamChanged() on it.
		stream.addEventListener('update', () => {
			if (this.stream !== stream) {
				return;
			}

			debug('MediaStream emits "update", calling native mediaStreamChanged()');

			exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_mediaStreamChanged', [this.id]);
		});

		// Subscribe to 'inactive' event and emit "close" so the video element can react.
		stream.addEventListener('inactive', () => {
			if (this.stream !== stream) {
				return;
			}

			debug(
				'MediaStream emits "inactive", emiting "close" and closing this MediaStreamRenderer'
			);

			this.dispatchEvent(new Event('close'));
			this.close();
		});

		const connected = () => {
			// Emit video events.
			this.element.dispatchEvent(new Event('loadedmetadata'));
			this.element.dispatchEvent(new Event('loadeddata'));
			this.element.dispatchEvent(new Event('canplay'));
			this.element.dispatchEvent(new Event('canplaythrough'));
		};

		if (stream.connected) {
			connected();
		} else {
			// Otherwise subscribe to 'connected' event to emulate video elements events.
			stream.addEventListener('connected', () => {
				if (this.stream !== stream) {
					return;
				}

				connected();
			});
		}
	}

	save(callback: (data: string | null) => any) {
		debug('save()');

		if (!this.stream) {
			callback(null);
			return;
		}

		function onResultOK(data: string) {
			callback(data);
		}

		function onResultError() {
			callback(null);
		}

		exec(onResultOK, onResultError, 'iosrtcPlugin', 'MediaStreamRenderer_save', [this.id]);
	}

	refresh() {
		debug('refresh()');

		const elementPositionAndSize = this.getElementPositionAndSize(),
			computedStyle = window.getComputedStyle(this.element);

		let elementLeft = elementPositionAndSize.left,
			elementTop = elementPositionAndSize.top,
			elementWidth = elementPositionAndSize.width,
			elementHeight = elementPositionAndSize.height;

		// get background color
		const backgroundColorRgba = computedStyle.backgroundColor
			.replace(/rgba?\((.*)\)/, '$1')
			.split(',')
			.map(function (x) {
				return x.trim();
			});
		backgroundColorRgba[3] = '0';
		this.element.style.backgroundColor = 'rgba(' + backgroundColorRgba.join(',') + ')';
		backgroundColorRgba.length = 3;

		// get padding values
		const paddingTop = parseInt(computedStyle.paddingTop) | 0,
			paddingBottom = parseInt(computedStyle.paddingBottom) | 0,
			paddingLeft = parseInt(computedStyle.paddingLeft) | 0,
			paddingRight = parseInt(computedStyle.paddingRight) | 0;

		// fix position according to padding
		elementLeft += paddingLeft;
		elementTop += paddingTop;

		// fix width and height according to padding
		elementWidth -= paddingLeft + paddingRight;
		elementHeight -= paddingTop + paddingBottom;

		let videoViewWidth = elementWidth,
			videoViewHeight = elementHeight;

		// visible
		let visible: boolean;
		if (computedStyle.visibility === 'hidden') {
			visible = false;
		} else {
			visible = !!this.element.offsetHeight; // Returns 0 if element or any parent is hidden.
		}

		// opacity
		const opacity = parseFloat(computedStyle.opacity);

		// zIndex
		const zIndex =
			parseFloat(computedStyle.zIndex) || parseFloat(this.element.style.zIndex) || 0;

		// mirrored (detect "-webkit-transform: scaleX(-1);" or equivalent)
		let mirrored: boolean;
		if (
			computedStyle.transform === 'matrix(-1, 0, 0, 1, 0, 0)' ||
			(computedStyle as any)['-webkit-transform'] === 'matrix(-1, 0, 0, 1, 0, 0)' ||
			computedStyle.webkitTransform === 'matrix(-1, 0, 0, 1, 0, 0)'
		) {
			mirrored = true;
		} else {
			mirrored = false;
		}

		// objectFit ('contain' is set as default value)
		let objectFit = computedStyle.objectFit || 'contain';

		// clip
		let clip: boolean;
		if (objectFit === 'none') {
			clip = false;
		} else {
			clip = true;
		}

		// borderRadius
		let borderRadius = parseFloat(computedStyle.borderRadius);
		if (/%$/.test(borderRadius.toString())) {
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

		const videoRatio = this.videoWidth / this.videoHeight;

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

		const elementRatio = elementWidth / elementHeight;

		switch (objectFit) {
			case 'cover':
				// The element has higher or equal width/height ratio than the video.
				if (elementRatio >= videoRatio) {
					videoViewWidth = elementWidth;
					videoViewHeight = videoViewWidth / videoRatio;
				} else if (elementRatio < videoRatio) {
					// The element has lower width/height ratio than the video.
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
				} else {
					// Same as 'contain'.
					if (elementRatio >= videoRatio) {
						// The element has higher or equal width/height ratio than the video.
						videoViewHeight = elementHeight;
						videoViewWidth = videoViewHeight * videoRatio;
					} else if (elementRatio < videoRatio) {
						// The element has lower width/height ratio than the video.
						videoViewWidth = elementWidth;
						videoViewHeight = videoViewWidth / videoRatio;
					}
				}
				break;

			default:
				// 'contain'.
				objectFit = 'contain';
				if (elementRatio >= videoRatio) {
					// The element has higher or equal width/height ratio than the video.
					videoViewHeight = elementHeight;
					videoViewWidth = videoViewHeight * videoRatio;
				} else if (elementRatio < videoRatio) {
					// The element has lower width/height ratio than the video.
					videoViewWidth = elementWidth;
					videoViewHeight = videoViewWidth / videoRatio;
				}
				break;
		}

		nativeRefresh.call(this);

		function hash(str: string) {
			let hash = 5381,
				i = str.length;

			while (i) {
				hash = (hash * 33) ^ str.charCodeAt(--i);
			}

			return hash >>> 0;
		}

		function nativeRefresh(this: MediaStreamRenderer) {
			const data = {
					elementLeft: Math.round(elementLeft),
					elementTop: Math.round(elementTop),
					elementWidth: Math.round(elementWidth),
					elementHeight: Math.round(elementHeight),
					videoViewWidth: Math.round(videoViewWidth),
					videoViewHeight: Math.round(videoViewHeight),
					visible: visible,
					backgroundColor: backgroundColorRgba.join(','),
					opacity: opacity,
					zIndex: zIndex,
					mirrored: mirrored,
					objectFit: objectFit,
					clip: clip,
					borderRadius: borderRadius
				},
				newRefreshCached = hash(JSON.stringify(data));

			if (newRefreshCached === this.refreshCached) {
				return;
			}

			this.refreshCached = newRefreshCached;

			debug('refresh() | [data:%o]', data);

			exec(null, null, 'iosrtcPlugin', 'MediaStreamRenderer_refresh', [this.id, data]);
		}
	}

	close() {
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
	}

	private onEvent(data: MediaStreamRendererEvent) {
		debug('onEvent() | [type:%s, data:%o]', data.type, data);

		switch (data.type) {
			case 'videoresize':
				this.videoWidth = data.size.width;
				this.videoHeight = data.size.height;
				this.refresh();

				const event = new Event(data.type);
				(event as any).videoWidth = data.size.width;
				(event as any).videoHeight = data.size.height;
				this.dispatchEvent(event);

				break;
		}
	}

	private getElementPositionAndSize() {
		const rect = this.element.getBoundingClientRect();

		return {
			left: rect.left + this.element.clientLeft,
			top: rect.top + this.element.clientTop,
			width: this.element.clientWidth,
			height: this.element.clientHeight
		};
	}
}
