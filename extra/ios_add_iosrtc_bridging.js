#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/Building.md#build-with-xcode

var fs = require("fs"),
	path = require("path"),
	xcode = require('xcode'),
	projectRoot = process.argv[2],

	BUILD_VERSION = '"8.0"',
	RUNPATH_SEARCH_PATHS = '"@executable_path/Frameworks"',
	BRIDGING_HEADER_END = '/Plugins/cordova-plugin-iosrtc/cordova-plugin-iosrtc-Bridging-Header.h"',
	COMMENT_KEY = /_comment$/,

	xcodeProject, projectName, swiftBridgingHead, xcodeProjectName, xcodeProjectPath;


// Helpers

// Returns the project name
function getProjectName(protoPath) {
	var cordovaConfigPath = path.join(protoPath, 'config.xml'),
		content = fs.readFileSync(cordovaConfigPath, 'utf-8');

	return /<name>([\s\S]*)<\/name>/mi.exec(content)[1].trim();
}

// Drops the comments
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


// Starting here

// Setting needed string variables once we get the project name
projectName = getProjectName(projectRoot);
swiftBridgingHead = '"' + projectName + BRIDGING_HEADER_END;
xcodeProjectName = projectName + '.xcodeproj';
xcodeProjectPath = path.join(projectRoot, 'platforms', 'ios', xcodeProjectName, 'project.pbxproj');

// Checking if the XCode project file is in the right place
if (!fs.existsSync(xcodeProjectPath)) {
	console.log('ERROR: An error occured searching the project file at: ""' +
	xcodeProjectPath + '": ' + JSON.stringify(error));

	return;
}
console.log('XCode project file found: ' + xcodeProjectPath);
xcodeProject = xcode.project(xcodeProjectPath);

// Throwing info about the tasks to do
console.log('Making the generated project compatible with XCode:');
console.log('- "iOS Deployment Target" and "Deployment Target" to: ' + BUILD_VERSION);
console.log('- "Runpath Search Paths" to: ' + RUNPATH_SEARCH_PATHS);
console.log('- "Objective-C Bridging Header" to: ' + swiftBridgingHead);

// Parsing the file
xcodeProject.parse(function (error) {
	var configurations, buildSettings;

	if (error) {
		console.log('ERROR: An error occured during the parse of the project file');
	} else {
		configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
		// Adding or changing the parameters we need
		Object.keys(configurations).forEach(function (config) {
			buildSettings = configurations[config].buildSettings;
			buildSettings.LD_RUNPATH_SEARCH_PATHS = RUNPATH_SEARCH_PATHS;
			buildSettings.SWIFT_OBJC_BRIDGING_HEADER = swiftBridgingHead;
			buildSettings.IPHONEOS_DEPLOYMENT_TARGET = BUILD_VERSION;
		});

		// Writing the file again
		fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), 'utf-8');
		console.log('File correctly fixed: ' + xcodeProjectPath);
	}
});
