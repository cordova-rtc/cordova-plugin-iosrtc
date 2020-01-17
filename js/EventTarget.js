/**
 * Dependencies.
 */
var
	YaetiEventTarget = require('yaeti').EventTarget;

var EventTarget = function () {
	YaetiEventTarget.call(this);
};

EventTarget.prototype = Object.create(YaetiEventTarget.prototype);
EventTarget.prototype.constructor = EventTarget;

/**
 * Expose the EventTarget class.
 */
module.exports = EventTarget;