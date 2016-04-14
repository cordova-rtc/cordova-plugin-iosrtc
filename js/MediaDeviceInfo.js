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
