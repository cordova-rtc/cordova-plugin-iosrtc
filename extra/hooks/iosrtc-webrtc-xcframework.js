#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/docs/Building.md

var fs = require('fs'),
	path = require('path'),
	exec = require('child_process').execSync;

// Helpers

function debug(msg) {
	console.log('iosrtc-swift-support.js [INFO] ' + msg);
}

function debugError(msg) {
	console.error('iosrtc-swift-support.js [ERROR] ' + msg);
	process.exit(1);
}

// Starting here

module.exports = function (context) {
	if (process.platform !== 'darwin') {
		return;
	}
	var projectRoot = context.opts.projectRoot,
		iosRTCProjectPath = path.join(projectRoot, 'plugins/cordova-plugin-iosrtc/lib'),
		webRTCFramework = path.join(iosRTCProjectPath, 'WebRTC.framework'),
		webRTCFrameworkIOS = path.join(iosRTCProjectPath, 'tmp/ios/WebRTC.framework'),
		webRTCFrameworkSIM = path.join(iosRTCProjectPath, 'tmp/sim/WebRTC.framework'),
		webRTCXCFramework = path.join(iosRTCProjectPath, 'WebRTC.xcframework');

	// Showing info about the tasks to do

	if (!fs.existsSync(webRTCFramework)) {
		debugError('an error occurred searching the project file at: "' + webRTCFramework + '"');
		return;
	}

	if (fs.existsSync(webRTCXCFramework)) {
		debug('xcframework already exists');
		return;
	}

	fs.mkdirSync(webRTCFrameworkIOS, {
		recursive: true
	});
	fs.mkdirSync(webRTCFrameworkSIM, {
		recursive: true
	});
	exec(`cp -r '${webRTCFramework}/'* '${webRTCFrameworkIOS}'`, {
		cwd: iosRTCProjectPath
	});
	exec(`cp -r '${webRTCFramework}/'* '${webRTCFrameworkSIM}'`, {
		cwd: iosRTCProjectPath
	});

	const ARCH_TYPES_REMOVE_FOR_SIM = ['armv7', 'arm64'];
	const ARCH_TYPES_REMOVE_FOR_IOS = ['x86_64', 'i386'];
	prepareFramework(webRTCFramework, ARCH_TYPES_REMOVE_FOR_SIM, webRTCFrameworkSIM);
	prepareFramework(webRTCFramework, ARCH_TYPES_REMOVE_FOR_IOS, webRTCFrameworkIOS);
	const generateXCCmd = `xcodebuild -create-xcframework -framework '${webRTCFrameworkIOS}' -framework '${webRTCFrameworkSIM}' -output '${iosRTCProjectPath}/WebRTC.xcframework'`;
	debug('Generating WebRTC.xcframework using ' + generateXCCmd);
	exec(generateXCCmd, {
		cwd: iosRTCProjectPath
	});
	exec(`rm -rf '${webRTCFramework}' '${iosRTCProjectPath}/tmp' `, {
		cwd: iosRTCProjectPath
	});
};

function prepareFramework(webRTCFramework, archTypes, folder) {
	var removeCmd = 'lipo ';
	archTypes.forEach((elm) => {
		// re-package device related archs only. ( armv7, arm64 )
		removeCmd += `-remove ${elm} `;
	});
	exec(removeCmd + ` WebRTC -o '${folder}/WebRTC'`, {
		cwd: webRTCFramework
	});
}
