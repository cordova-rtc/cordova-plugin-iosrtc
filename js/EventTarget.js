/**
 * @author mrdoob / http://mrdoob.com
 * @author Jesús Leganés Combarro "Piranna" <piranna@gmail.com>
 */


/**
 * Specification: https://dom.spec.whatwg.org
 */


/**
 * Expose the EventTarget class.
 */
module.exports = EventTarget;


function EventTarget() {
	var listeners = {};

	this.addEventListener = function (type, newListener) {
		var listenersType,
			i, listener;

		if (!type || !newListener) {
			return;
		}

		listenersType = listeners[type];
		if (listenersType === undefined) {
			listeners[type] = listenersType = [];
		}

		for (i = 0; !!(listener = listenersType[i]); i++) {
			if (listener === newListener) {
				return;
			}
		}

		listenersType.push(newListener);
	};

	this.removeEventListener = function (type, oldListener) {
		var listenersType,
			i, listener;

		if (!type || !oldListener) {
			return;
		}

		listenersType = listeners[type];
		if (listenersType === undefined) {
			return;
		}

		for (i = 0; !!(listener = listenersType[i]); i++) {
			if (listener === oldListener) {
				listenersType.splice(i, 1);
				break;
			}
		}

		if (listenersType.length === 0) {
			delete listeners[type];
		}
	};

	this.dispatchEvent = function (event) {
		var type,
			listenersType,
			dummyListener,
			stopImmediatePropagation = false,
			i, listener;

		if (!(event instanceof Event)) {
			throw new Error('first argument must be an instance of Event');
		}

		if (event._dispatched) {
			throw new Error('Event already dispatched');
		}
		event._dispatched = true;

		// Force the event to be cancelable.
		event.cancelable = true;
		event.target = this;

		// Override stopImmediatePropagation() function.
		event.stopImmediatePropagation = function () {
			stopImmediatePropagation = true;
		};

		type = event.type;
		listenersType = (listeners[type] || []);

		dummyListener = this['on' + type];
		if (typeof dummyListener === 'function') {
			listenersType.push(dummyListener);
		}

		for (i = 0; !!(listener = listenersType[i]); i++) {
			if (stopImmediatePropagation) {
				break;
			}

			listener.call(this, event);
		}

		return !event.defaultPrevented;
	};
}
