function createErrorClass(name: string) {
	// eslint-disable-next-line @typescript-eslint/no-unused-vars
	return class NamedError extends Error {
		name = name;

		constructor(public readonly message: string) {
			super(message);
		}
	};
}

export const Errors = {
	InvalidStateError: createErrorClass('InvalidStateError'),
	InvalidSessionDescriptionError: createErrorClass('InvalidSessionDescriptionError'),
	MediaStreamError: createErrorClass('MediaStreamError')
};

// Detect callback usage to assist 5.0.1 to 5.0.2 migration
// TODO remove on 6.0.0
export function detectDeprecatedCallbaksUsage(funcName: string, args: IArguments) {
	if (typeof args[1] === 'function' || typeof args[2] === 'function') {
		throw new Error(
			'Callbacks are not supported by "' + funcName + '" anymore, use Promise instead.'
		);
	}
}
