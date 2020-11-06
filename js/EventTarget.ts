const YaetiEventTarget = require('yaeti').EventTarget;

// Implement official EventTarget to ensure usages get proper types
export class EventTargetShim extends YaetiEventTarget implements EventTarget {
	readonly target = this;

	constructor() {
		super();
	}

	addEventListener(
		type: string,
		listener: EventListenerOrEventListenerObject | null,
		options?: boolean | AddEventListenerOptions
	): void {
		super.addEventListener(type, listener, options);
	}

	dispatchEvent(event: Event): boolean {
		return super.dispatchEvent(event);
	}

	removeEventListener(
		type: string,
		callback: EventListenerOrEventListenerObject | null,
		options?: EventListenerOptions | boolean
	): void {
		return super.removeEventListener(type, callback, options);
	}
}
