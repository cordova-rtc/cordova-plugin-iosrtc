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

export function extendEventTarget(target: any) {
	EventTargetShim.call(target);
	const eventTargetPrototype = Object.getOwnPropertyDescriptors(EventTargetShim.prototype);

	// this prevents the extend target from showing up as an `EventTargetShim` object, keeping it's original constructor
	delete (eventTargetPrototype as any).constructor;

	Object.defineProperties(target, eventTargetPrototype);
}
