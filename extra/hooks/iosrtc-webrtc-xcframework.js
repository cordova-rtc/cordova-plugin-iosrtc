#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/docs/Building.md

var fs = require('fs'),
	path = require('path'),
	xcode = require('xcode'),
	xmlEntities = new (require('html-entities').XmlEntities)(),
	DISABLE_IOSRTC_HOOK = process.env.DISABLE_IOSRTC_HOOK ? true : false,
	IPHONEOS_DEPLOYMENT_TARGET = process.env.IPHONEOS_DEPLOYMENT_TARGET || '10.2',
	IPHONEOS_DEPLOYMENT_TARGET_XCODE = '"' + IPHONEOS_DEPLOYMENT_TARGET + '"',
	SWIFT_VERSION = process.env.SWIFT_VERSION || '4.2',
	SWIFT_VERSION_XCODE = '"' + SWIFT_VERSION + '"',
	RUNPATH_SEARCH_PATHS = '@executable_path/Frameworks',
	RUNPATH_SEARCH_PATHS_XCODE = '"' + RUNPATH_SEARCH_PATHS + '"',
	ENABLE_BITCODE = 'NO',
	ENABLE_BITCODE_XCODE = '"' + ENABLE_BITCODE + '"',
	UNIFIED_BRIDGING_HEADER = 'Plugins/Unified-Bridging-Header.h',
	IOSRTC_BRIDGING_HEADER = 'cordova-plugin-iosrtc-Bridging-Header.h',
	BRIDGING_HEADER_END = '/Plugins/cordova-plugin-iosrtc/' + IOSRTC_BRIDGING_HEADER,
	TEST_UNIFIED_BRIDGING_HEADER = process.env.TEST_UNIFIED_BRIDGING_HEADER ? true : false; // Set to true to test handling of existing swift bridging header

// Helpers

// Returns the project name
function getProjectName(protoPath) {
	var cordovaConfigPath = path.join(protoPath, 'config.xml'),
		content = fs.readFileSync(cordovaConfigPath, 'utf-8');

	var name = /<name>([\s\S]*)<\/name>/im.exec(content)[1].trim();

	return xmlEntities.decode(name);
}

// Drops the comments
var COMMENT_KEY = /_comment$/;
function nonComments(obj) {
	var keys = Object.keys(obj),
		newObj = {},
		i = 0;

	for (i; i < keys.length; i += 1) {
		if (!COMMENT_KEY.test(keys[i])) {
			newObj[keys[i]] = obj[keys[i]];
		}
	}

	return newObj;
}

function matchBuildSettingsValue(value, expectedValue) {
	return value === expectedValue;
}

function hasBuildSettingsValue(value, expectedValue) {
	return (
		value &&
		(matchBuildSettingsValue(value, expectedValue) || value.indexOf(expectedValue) !== -1)
	);
}

function convertToFloat(value) {
	return parseFloat(value.replace(/[^\d.-]/g, ''), 10);
}

function matchMinValue(value, minValue) {
	//console.log('matchMinValue', value, minValue)
	return value && convertToFloat(value) >= convertToFloat(minValue);
}

function matchBuildSettingsMinValue(value, expectedValue) {
	return (
		value &&
		(matchBuildSettingsValue(value, expectedValue) || matchMinValue(value, expectedValue))
	);
}

function matchXcconfigPathValue(swiftOptions, path, expectedValue) {
	return (
		swiftOptions.filter(function (swiftOption) {
			return swiftOption === path + ' = ' + expectedValue;
		}).length > 0
	);
}

function getXcconfigPathValue(swiftOptions, path) {
	var swiftOption = swiftOptions.filter(function (swiftOption) {
		return swiftOption.indexOf(path + ' = ') === 0;
	})[0];

	return swiftOption ? swiftOption.split(' = ')[1] : '';
}

function matchXcconfigMinValue(swiftOptions, path, expectedValue) {
	var swiftOption = swiftOptions.find(function (swiftOption) {
		return swiftOption.split(' = ')[0] === path;
	});

	return swiftOption && matchMinValue(swiftOption.split(' = ')[1], expectedValue);
}

function getRelativeToProjectRootPath(path, projectRoot) {
	return path.replace(projectRoot, '.');
}

function readFileLines(filePath) {
	return fs.readFileSync(filePath).toString().split('\n');
}

function debug(msg) {
	console.log('iosrtc-swift-support.js [INFO] ' + msg);
}

function debugError(msg) {
	console.error('iosrtc-swift-support.js [ERROR] ' + msg);
	process.exit(1);
}

// Starting here

module.exports = function (context) {
	/*
	 */

	if (DISABLE_IOSRTC_HOOK) {
		debug('cordova-plugin-iosrtc hook is disabled');
		return;
	}

	var projectRoot = context.opts.projectRoot,
		projectName = getProjectName(projectRoot),
		platformPath = path.join(projectRoot, 'platforms', 'ios'),
		iosRTCProjectPath = path.join(projectRoot, 'plugins/cordova-plugin-iosrtc/lib'),
		webRTCFramework = path.join(iosRTCProjectPath, 'WebRTC.framework'),
		webRTCFrameworkIOS = path.join(iosRTCProjectPath, 'tmp/ios/WebRTC.framework'),
		webRTCFrameworkSIM = path.join(iosRTCProjectPath, 'tmp/sim/WebRTC.framework'),
		webRTCXCFramework = path.join(iosRTCProjectPath, "WebRTC.xcframework");

	// Showing info about the tasks to do

	if (!fs.existsSync(webRTCFramework)) {
		debugError('an error occurred searching the project file at: "' + webRTCFramework + '"');
		return;
	}

	if (fs.existsSync(webRTCXCFramework)) {
		debug("xcframework already exists");
		return;
	}
	
	const exec = require('child_process').execSync;
	fs.mkdirSync(webRTCFrameworkIOS);
	fs.mkdirSync(webRTCFrameworkSIM);
	fs.copyFileSync(webRTCFramework, webRTCFrameworkIOS);
	fs.copyFileSync(webRTCFramework, webRTCFrameworkSIM);
	
	const ARCH_TYPES_REMOVE_FOR_SIM = ['armv7, arm64'];
	const ARCH_TYPES_REMOVE_FOR_IOS = ['x86_64', 'i386'];
	prepareFramework(ARCH_TYPES_REMOVE_FOR_SIM, webRTCFrameworkSIM);
	prepareFramework(ARCH_TYPES_REMOVE_FOR_IOS, webRTCFrameworkIOS);

	exec(`xcodebuild -create-xcframework -framework ${webRTCFrameworkIOS} -framework ${webRTCFrameworkSIM} -output ${iosRTCProjectPath}/WebRTC.xcframework`, {
		cwd: iosRTCProjectPath
	});
	fs.rmdirSync(webRTCFramework);
	fs.rmdirSync(`iosRTCProjectPath/tmp`);

};
function prepareFramework(archTypes, folder){
	archTypes.forEach(elm => {
        exec(`lipo -remove ${elm} WebRTC -o WebRTC`, {
            cwd: folder
        });
        // re-package device related archs only. ( armv7, arm64 )
    });
}
