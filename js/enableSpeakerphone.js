/**
 * Expose the enableSpeakerphone function.
 */
module.exports = enableSpeakerphone;

/**
 * Dependencies.
 */
var debug = require('debug')('iosrtc:enableSpeakerphone'),
	exec = require('cordova/exec');


function enableSpeakerphone() {

	debug('enableSpeakerphone()');

	exec(null, null, 'iosrtcPlugin', 'enableSpeakerphone', []);
}