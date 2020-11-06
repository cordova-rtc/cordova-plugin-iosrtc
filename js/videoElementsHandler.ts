import debugBase from 'debug';
import { MediaStreamRenderer, mediaStreamRenderers } from './MediaStreamRenderer';
import { MediaStreamShim, mediaStreams } from './MediaStream';

interface NodeWithVideoHandle extends Node {
	_iosrtcVideoHandled?: true;
}

interface HTMLVideoHandle extends HTMLVideoElement {
	_iosrtcMediaStreamRendererId?: number;
}

const debug = debugBase('iosrtc:videoElementsHandler'),
	/**
	 * Local variables.
	 */
	// RegExp for Blob URI.
	BLOB_INTERNAL_URI_REGEX = new RegExp(/^blob:/),
	// Video element mutation observer.
	videoObserver = new MutationObserver((mutations) => {
		mutations.forEach((mutation) => {
			// HTML video element.
			const video = mutation.target as HTMLVideoElement;

			// .srcObject removed.
			if (!video.srcObject && !video.src) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);
				return;
			}

			handleVideo(video);
		});
	}),
	checkNewNode = (node: NodeWithVideoHandle) => {
		if (node.nodeName === 'VIDEO') {
			debug('new video element added');

			// Avoid same node firing more than once (really, may happen in some cases).
			if (node._iosrtcVideoHandled) {
				return;
			}
			node._iosrtcVideoHandled = true;

			// Observe changes in the video element.
			observeVideo(node as HTMLVideoHandle);
		} else {
			node.childNodes.forEach(checkNewNode);
		}
	},
	checkRemovedNode = (node: NodeWithVideoHandle) => {
		if (node.nodeName === 'VIDEO') {
			debug('video element removed');

			// If this video element was previously handling a MediaStreamRenderer, release it.
			releaseMediaStreamRenderer(node as HTMLVideoHandle);
			delete node._iosrtcVideoHandled;
		} else {
			node.childNodes.forEach(checkRemovedNode);
		}
	},
	// DOM mutation observer.
	domObserver = new MutationObserver((mutations) => {
		mutations.forEach((mutation) => {
			// Check if there has been addition or deletion of nodes.
			if (mutation.type !== 'childList') {
				return;
			}

			// Check added nodes.
			mutation.addedNodes.forEach(checkNewNode);

			// Check removed nodes.
			mutation.removedNodes.forEach(checkRemovedNode);
		});
	});

export function refreshVideos() {
	debug('refreshVideos()');

	Object.values(mediaStreamRenderers).forEach((renderer) => renderer.refresh());
}

export function initializeVideoElementsHandler() {
	const existingVideos = document.querySelectorAll('video');

	// Search the whole document for already existing HTML video elements and observe them.
	existingVideos.forEach((video) => {
		debug('video element found');
		observeVideo(video);
	});

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

export function observeVideo(video: HTMLVideoHandle) {
	debug('observeVideo()');

	// If the video already has a srcObject property but is not yet handled by the plugin
	// then handle it now.
	const hasStream = video.srcObject || video.src;
	if (hasStream && !video._iosrtcMediaStreamRendererId) {
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
		attributeFilter: ['srcObject', 'src']
	});

	// MutationObserver fail to trigger when using srcObject on ony tested browser.
	// But video.srcObject = new MediaStream() will trigger onloadstart and
	// video.srcObject = null will trigger onemptied events.

	video.addEventListener('loadstart', function () {
		const hasStream = video.srcObject || video.src;

		if (hasStream && !video._iosrtcMediaStreamRendererId) {
			// If this video element was NOT previously handling a MediaStreamRenderer, release it.
			handleVideo(video);
		} else if (hasStream && video._iosrtcMediaStreamRendererId) {
			// The video element has received a new srcObject.
			const stream = video.srcObject as MediaStreamShim | MediaProvider;
			if (stream && 'getBlobId' in stream) {
				// Release previous renderer
				releaseMediaStreamRenderer(video);
				// Install new renderer
				provideMediaStreamRenderer(video, stream.getBlobId());
			}
		}
	});

	video.addEventListener('emptied', function () {
		const hasStream = video.srcObject || video.src;
		if (!hasStream && video._iosrtcMediaStreamRendererId) {
			// If this video element was previously handling a MediaStreamRenderer, release it.
			releaseMediaStreamRenderer(video);
		}
	});

	// Intercept video 'error' events if it's due to the attached MediaStream.
	video.addEventListener('error', function (event) {
		if (
			video.error?.code === window.MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED &&
			BLOB_INTERNAL_URI_REGEX.test(video.src)
		) {
			debug('stopping "error" event propagation for video element');

			event.stopImmediatePropagation();
		}
	});
}

/**
 * Private API.
 */

function handleVideo(video: HTMLVideoHandle) {
	// The app has set video.srcObject.
	if (video.srcObject) {
		const stream = video.srcObject as MediaStreamShim | MediaProvider;
		if (stream && 'getBlobId' in stream) {
			if (!stream.getBlobId()) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);

				return;
			}

			provideMediaStreamRenderer(video, stream.getBlobId());
		}
	} else if (video.src) {
		const xhr = new XMLHttpRequest();
		xhr.open('GET', video.src, true);
		xhr.responseType = 'blob';
		xhr.onload = function () {
			if (xhr.status !== 200) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);

				return;
			}

			const reader = new FileReader();

			// Some versions of Safari fail to set onloadend property, some others do not react
			// on 'loadend' event. Try everything here.
			try {
				reader.onloadend = onloadend;
			} catch (error) {
				reader.addEventListener('loadend', onloadend);
			}
			reader.readAsText(xhr.response);

			function onloadend() {
				const mediaStreamBlobId = reader.result;

				// The retrieved URL does not point to a MediaStream.
				if (!mediaStreamBlobId || typeof mediaStreamBlobId !== 'string') {
					// If this video element was previously handling a MediaStreamRenderer, release it.
					releaseMediaStreamRenderer(video);

					return;
				}

				provideMediaStreamRenderer(video, mediaStreamBlobId);
			}
		};
		xhr.send();
	}
}

function provideMediaStreamRenderer(video: HTMLVideoHandle, mediaStreamBlobId: string) {
	const mediaStream = mediaStreams[mediaStreamBlobId];
	let mediaStreamRenderer = mediaStreamRenderers[video._iosrtcMediaStreamRendererId || -1];

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
		if (
			!video._iosrtcMediaStreamRendererId ||
			mediaStreamRenderers[video._iosrtcMediaStreamRendererId] !== mediaStreamRenderer
		) {
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
				if (
					mediaStreamRenderer &&
					mediaStreamRenderer.stream &&
					mediaStreamRenderer.stream.connected
				) {
					return video.HAVE_ENOUGH_DATA;
				} else {
					return video.HAVE_NOTHING;
				}
			}
		}
	});
}

function releaseMediaStreamRenderer(video: HTMLVideoHandle) {
	if (!video._iosrtcMediaStreamRendererId) {
		return;
	}

	const mediaStreamRenderer = mediaStreamRenderers[video._iosrtcMediaStreamRendererId];

	if (mediaStreamRenderer) {
		delete mediaStreamRenderers[video._iosrtcMediaStreamRendererId];
		mediaStreamRenderer.close();
	}

	delete video._iosrtcMediaStreamRendererId;

	// Remove overridden <video> properties.
	delete (video as any).videoWidth;
	delete (video as any).videoHeight;
	delete (video as any).readyState;
}
