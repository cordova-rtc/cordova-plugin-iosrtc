class RTCStatsReport {
	constructor(data) {
		this.data = new Map((data || []).map((el) => [el.reportId, el]));
	}

	get size() {
		return this.data.size;
	}

	has(key) {
		return this.data.has(key);
	}
	get(key) {
		return this.data.get(key);
	}
	forEach(callbackfn, thisArg) {
		return this.data.forEach(callbackfn, thisArg);
	}

	keys() {
		return this.data.keys();
	}
	values() {
		return this.data.values();
	}
	entries() {
		return this.data.entries();
	}
	*[Symbol.iterator]() {
		for (const value of this.data) {
			yield value;
		}
	}
}

/**
 * Expose the RTCStatsReport class.
 */
module.exports = RTCStatsReport;
