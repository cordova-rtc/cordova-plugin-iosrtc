/**
 * Expose an object with WebRTC Errors.
 */
var Errors = module.exports = {},


/**
 * Local variables.
 */
	IntermediateInheritor = function () {};


IntermediateInheritor.prototype = Error.prototype;


/**
 * Create error classes.
 */
addError('InvalidStateError');
addError('InvalidSessionDescriptionError');
addError('InternalError');
addError('MediaStreamError');


function addError(name) {
	Errors[name] = function () {
		var tmp = Error.apply(this, arguments);

		this.name = tmp.name = name;
		this.message = tmp.message;

		Object.defineProperty(this, 'stack', {
			get: function () {
				return tmp.stack;
			}
		});

		return this;
	};

	Errors[name].prototype = new IntermediateInheritor();
}

// Detect callback usage to assist 5.0.1 to 5.0.2 migration
// TODO remove on 6.0.0
Errors.detectDeprecatedCallbaksUsage = function detectDeprecatedCallbaksUsage(funcName, arg) {
	if (
		typeof arg[1] === 'function' ||
			typeof arg[2] === 'function'
	) {
		throw new Error('Callbacks are not supported by "' + funcName + '" anymore, use Promise instead.');
	}
};