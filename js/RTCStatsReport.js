/**
 * Expose the RTCStatsReport class.
 */
module.exports = RTCStatsReport;

function RTCStatsReport(data) {
	data = data || [];

	this.id = data.reportId;
	this.timestamp = data.timestamp;
	this.type = data.type;

	this.names = function () {
		return Object.keys(data.values);
	};

	this.stat = function (key) {
		return data.values[key] || '';
	};
}
