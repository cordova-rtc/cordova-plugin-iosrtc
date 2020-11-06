export interface RTCSessionDescriptionAsJSON {
	sdp: string;
	type: RTCSdpType;
}

export class RTCSessionDescriptionShim implements RTCSessionDescription {
	sdp: string;
	type: RTCSdpType;

	constructor(descriptionInitDict: RTCSessionDescriptionAsJSON) {
		this.sdp = descriptionInitDict.sdp;
		this.type = descriptionInitDict.type;
	}

	toJSON() {
		return this;
	}
}
