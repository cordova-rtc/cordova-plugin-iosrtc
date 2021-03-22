class RTCStatsReport {
	constructor(data) {
		const arr = data || [];
		this.data = {};
		arr.forEach((el) => {
			this.data[el.reportId] = el;
		});
		this.size = arr.length;
	}

	entries() {
		return this.keys().map((k) => [k, this.data[k]]);
	}

	keys() {
		return Object.getOwnPropertyNames(this.data);
	}

	values() {
		return this.keys().map((k) => this.data[k]);
	}

	get(key) {
		return this.data[key];
	}
}

/**
 * Expose the RTCStatsReport class.
 */
module.exports = RTCStatsReport;
