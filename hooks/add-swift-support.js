// This file to be added to the <platform name="ios"> tag of your plugin.xml like this:
// <hook type="after_plugin_install" src="hooks/addSwiftOptions.js" />


var fs = require('fs'),
	path = require('path');


module.exports = function (context) {
	var projectRoot = context.opts.projectRoot,
		xcconfigPath = path.join(projectRoot, '/platforms/ios/cordova/build.xcconfig'),
		pluginDir = context.opts.plugin.dir,
		swiftOptions = ['']; // <-- begin to file appending AFTER initial newline

	swiftOptions.push('IPHONEOS_DEPLOYMENT_TARGET = 8.2');
	swiftOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + path.join(pluginDir, '/src/cordova-plugin-iosrtc-Bridging-Header.h'));
	swiftOptions.push('LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks');
	// swiftOptions.push('EMBEDDED_CONTENT_CONTAINS_SWIFT = YES');  // NOTE: Not needed.

	fs.appendFileSync(xcconfigPath, swiftOptions.join('\n'));
};

