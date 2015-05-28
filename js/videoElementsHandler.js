/**
 * Expose a function that must be called when the library is loaded.
 */
module.exports = videoElementsHandler;


/**
 * Dependencies.
 */
var debug = require('debug')('iosrtc:videoElementsHandler'),
	MediaStreamRenderer = require('./MediaStreamRenderer'),


/**
 * Local variables.
 */

	// RegExp for MediaStream blobId.
	MEDIASTREAM_ID_REGEXP = new RegExp(/^MediaStream_/),

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
		var i, numMutations, mutation,
			video;

		for (i = 0, numMutations = mutations.length; i < numMutations; i++) {
			mutation = mutations[i];

			// HTML video element.
			video = mutation.target;

			// .src removed.
			if (!video.src) {
				// If this video element was previously handling a MediaStreamRenderer, release it.
				releaseMediaStreamRenderer(video);

				continue;
			}

			handleVideo(video);
		}

		function handleVideo(video) {
			var xhr = new XMLHttpRequest();

			xhr.open('GET', video.src, true);
			xhr.responseType = 'blob';
			xhr.onload = function () {
				if (xhr.status !== 200) {
					// If this video element was previously handling a MediaStreamRenderer, release it.
					releaseMediaStreamRenderer(video);

					return;
				}

				var reader = new FileReader();

				reader.onloadend = function () {
					var mediaStreamBlobId = reader.result;

					// The retrieved URL does not point to a MediaStream.
					if (!mediaStreamBlobId || typeof mediaStreamBlobId !== 'string' || !mediaStreamBlobId.match(MEDIASTREAM_ID_REGEXP)) {
						// If this video element was previously handling a MediaStreamRenderer, release it.
						releaseMediaStreamRenderer(video);

						return;
					}

					provideMediaStreamRenderer(video, mediaStreamBlobId);
				};
				reader.readAsText(xhr.response);
			};
			xhr.send();
		}
	}),

	// DOM mutation observer.
	domObserver = new MutationObserver(function (mutations) {
		var i, numMutations, mutation,
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
			} else {
				for (j = 0; j < node.childNodes.length; j++) {
					childNode = node.childNodes.item(j);

					checkRemovedNode(childNode);
				}
			}
		}
	});


function videoElementsHandler(_mediaStreams, _mediaStreamRenderers) {
	var existingVideos = document.querySelectorAll('video'),
		i, len,
		video;

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


/**
 * Private API.
 */

function observeVideo(video) {
	// Add .src observer to the video element.
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
		// TODO: Add srcObject, mozSrcObject
		attributeFilter: ['src']
	});
}


function provideMediaStreamRenderer(video, mediaStreamBlobId) {
	var mediaStream = mediaStreams[mediaStreamBlobId],
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
}


function releaseMediaStreamRenderer(video) {
	var mediaStreamRenderer = mediaStreamRenderers[video._iosrtcMediaStreamRendererId];

	delete video._iosrtcMediaStreamRendererId;

	if (mediaStreamRenderer) {
		delete mediaStreamRenderers[video._iosrtcMediaStreamRendererId];
		mediaStreamRenderer.close();
	}
}
