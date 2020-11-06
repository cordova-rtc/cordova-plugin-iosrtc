export class MediaDeviceInfoShim implements MediaDeviceInfo {
	readonly deviceId = this.data.deviceId;
	readonly kind = this.data.kind;
	readonly label = this.data.label;
	readonly groupId = this.data.groupId;
	// SourceInfo old spec.
	readonly id = this.data.deviceId;
	// Deprecated, but useful until there is an alternative
	readonly facing = '';

	constructor(private data: MediaDeviceInfo) {}

	toJSON(): any {
		return this;
	}
}
