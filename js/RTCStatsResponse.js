/**
 * Expose the RTCStatsResponse class.
 */
module.exports = RTCStatsResponse;

function RTCStatsResponse(data) {
	data = data || [];

	this.result = function () {
		return data;
	};

	this.forEach = function (callback, thisArg) {
		return data.forEach(callback, thisArg);
	};

	this.namedItem = function () {
		return null;
	};

	this.values = function () {
		return data;
	};
}
