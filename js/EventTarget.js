/**
 * Expose the EventTarget class.
 */
module.exports = EventTarget;

/**
 * Dependencies.
 */
var 
	YaetiEventTarget = require('yaeti').EventTarget;

/**
 * Expose the EventTarget class.
 */
function EventTarget() {

	// Prevent yaeti doing nothing if called for a native EventTarget object..
	if (typeof this.addEventListener === 'function') {
		delete this.addEventListener;
	}
	
	var eventTarget = YaetiEventTarget.call(this, arguments);

	return eventTarget;
}

EventTarget.prototype = Object.create(YaetiEventTarget.prototype);

EventTarget.prototype.constructor = EventTarget;