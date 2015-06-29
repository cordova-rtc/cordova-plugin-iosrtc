#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/eface2face/cordova-plugin-iosrtc/blob/master/docs/Building.md

var fs = require("fs"),
	path = require("path"),
	xcode = require('xcode'),

	BUILD_VERSION = '8.2',
	BUILD_VERSION_XCODE = '"' + BUILD_VERSION + '"',
	RUNPATH_SEARCH_PATHS = '@executable_path/Frameworks',
	RUNPATH_SEARCH_PATHS_XCODE = '"' + RUNPATH_SEARCH_PATHS + '"',

	BRIDGING_HEADER_END = '/Plugins/cordova-plugin-iosrtc/cordova-plugin-iosrtc-Bridging-Header.h',
	COMMENT_KEY = /_comment$/;


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

module.exports = function (context) {
	var projectRoot = context.opts.projectRoot,
		projectName = getProjectName(projectRoot),
		xcconfigPath = path.join(projectRoot, '/platforms/ios/cordova/build.xcconfig'),
		xcodeProjectName = projectName + '.xcodeproj',
		xcodeProjectPath = path.join(projectRoot, 'platforms', 'ios', xcodeProjectName, 'project.pbxproj'),
		swiftBridgingHead = projectName + BRIDGING_HEADER_END,
		swiftBridgingHeadXcode = '"' + swiftBridgingHead + '"',
		swiftOptions = [''], // <-- begin to file appending AFTER initial newline
		xcodeProject;

	// Checking if the project files are in the right place
	if (!fs.existsSync(xcodeProjectPath)) {
		console.error('ERROR: An error occured searching the project file at: "' + xcodeProjectPath + '"');

		return;
	}
	console.log('".pbxproj" project file found: ' + xcodeProjectPath);
	if (!fs.existsSync(xcconfigPath)) {
		console.error('ERROR: An error occured searching the project file at: "' + xcconfigPath + '"');

		return;
	}
	console.log('".xcconfig" project file found: ' + xcconfigPath);
	xcodeProject = xcode.project(xcodeProjectPath);

	// Showing info about the tasks to do
	console.log('Fixing issues in the generated project files:');
	console.log('- "iOS Deployment Target" and "Deployment Target" to: ' + BUILD_VERSION_XCODE);
	console.log('- "Runpath Search Paths" to: ' + RUNPATH_SEARCH_PATHS_XCODE);
	console.log('- "Objective-C Bridging Header" to: ' + swiftBridgingHeadXcode);


	// Massaging the files

	// "build.xcconfig"
	swiftOptions.push('LD_RUNPATH_SEARCH_PATHS = ' + RUNPATH_SEARCH_PATHS);
	swiftOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + swiftBridgingHead);
	swiftOptions.push('IPHONEOS_DEPLOYMENT_TARGET = ' + BUILD_VERSION);
	// NOTE: Not needed
	// swiftOptions.push('EMBEDDED_CONTENT_CONTAINS_SWIFT = YES');
	fs.appendFileSync(xcconfigPath, swiftOptions.join('\n'));
	console.log('File correctly fixed: ' + xcconfigPath);

	// "project.pbxproj"
	// Parsing it
	xcodeProject.parse(function (error) {
		var configurations, buildSettings;

		if (error) {
			console.error('ERROR: An error occured during the parse of the project file');
		} else {
			configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
			// Adding or changing the parameters we need
			Object.keys(configurations).forEach(function (config) {
				buildSettings = configurations[config].buildSettings;
				buildSettings.LD_RUNPATH_SEARCH_PATHS = RUNPATH_SEARCH_PATHS_XCODE;
				buildSettings.SWIFT_OBJC_BRIDGING_HEADER = swiftBridgingHeadXcode;
				buildSettings.IPHONEOS_DEPLOYMENT_TARGET = BUILD_VERSION_XCODE;
			});

			// Writing the file again
			fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), 'utf-8');
			console.log('File correctly fixed: ' + xcodeProjectPath);
		}
	});

};
