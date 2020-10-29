/**
 * Dependencies.
 */
var YaetiEventTarget = require('yaeti').EventTarget;

var EventTarget = function () {
	YaetiEventTarget.call(this);
};

EventTarget.prototype = Object.create(YaetiEventTarget.prototype);
EventTarget.prototype.constructor = EventTarget;

Object.defineProperties(
	EventTarget.prototype,
	Object.getOwnPropertyDescriptors(YaetiEventTarget.prototype)
);

EventTarget.prototype.dispatchEvent = function (event) {
	Object.defineProperty(event, 'target', {
		value: this,
		writable: false
	});

	YaetiEventTarget.prototype.dispatchEvent.call(this, event);
};

/**
 * Expose the EventTarget class.
 */
module.exports = EventTarget;
