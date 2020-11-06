import { RTCStatsShim } from './RTCStats';

export class RTCStatsReportShim implements RTCStatsReport {
	size = this.data.length;

	constructor(private data: RTCStatsShim[]) {}

	result() {
		return this.data;
	}

	keys() {
		return this.data.map((rtcStats) => rtcStats.id);
	}

	get(id: string) {
		return this.data.find((rtcStats) => rtcStats.id === id);
	}

	forEach(
		callbackfn: (value: any, key: string, parent: RTCStatsReport) => void,
		thisArg?: any
	): void {
		Object.values(this.data).forEach((rtcStats) => {
			callbackfn.apply(thisArg, [rtcStats, rtcStats.id, this]);
		});
	}

	namedItem() {
		return null;
	}
}
