export interface RTCStatsAsJSON {
	reportId: string;
	timestamp: number;
	type: RTCStatsType;
	values: {
		[key: string]: string;
	};
}

export class RTCStatsShim implements RTCStats {
	readonly id = this.data.reportId;
	readonly timestamp = this.data.timestamp;
	readonly type = this.data.type;

	constructor(private data: RTCStatsAsJSON) {
		Object.assign(this, data.values);
	}

	names() {
		return Object.keys(this.data.values);
	}

	stat(key: string) {
		return this.data.values[key] || '';
	}
}
