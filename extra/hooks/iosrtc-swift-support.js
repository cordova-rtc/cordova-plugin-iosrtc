#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/docs/Building.md

var
	fs = require("fs"),
	path = require("path"),
	xcode = require('xcode'),

	IPHONEOS_DEPLOYMENT_TARGET = '10.2',
	IPHONEOS_DEPLOYMENT_TARGET_XCODE = '"' + IPHONEOS_DEPLOYMENT_TARGET + '"',
	SWIFT_VERSION = '4.2',
	SWIFT_VERSION_XCODE = '"' + SWIFT_VERSION + '"',
	RUNPATH_SEARCH_PATHS = '@executable_path/Frameworks',
	RUNPATH_SEARCH_PATHS_XCODE = '"' + RUNPATH_SEARCH_PATHS + '"',
	ENABLE_BITCODE = 'NO',
	ENABLE_BITCODE_XCODE = '"' + ENABLE_BITCODE + '"',
	BRIDGING_HEADER_END = '/Plugins/cordova-plugin-iosrtc/cordova-plugin-iosrtc-Bridging-Header.h',
	COMMENT_KEY = /_comment$/;


// Helpers

// Returns the project name
function getProjectName(protoPath) {
	var
		cordovaConfigPath = path.join(protoPath, 'config.xml'),
		content = fs.readFileSync(cordovaConfigPath, 'utf-8');

	return /<name>([\s\S]*)<\/name>/mi.exec(content)[1].trim();
}

// Drops the comments
function nonComments(obj) {
	var
		keys = Object.keys(obj),
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
	return value && (matchBuildSettingsValue(value, expectedValue) || value.indexOf(expectedValue) !== -1);
}

function convertToFloat(value) {
	return value.replace(/[^\d.-]/g,'');
}

function matchMinValue(value, minValue) {
	return typeof value === 'string' && convertToFloat(value) >= convertToFloat(minValue);
}

function matchBuildSettingsMinValue(value, expectedValue) {
	return value && (matchBuildSettingsValue(value, expectedValue) || matchMinValue(value, expectedValue));
}

function matchXcconfigPathValue(swiftOptions, path, expectedValue) {
	return swiftOptions.filter(function (swiftOption) {
		return swiftOption === path + ' = ' + expectedValue;
	}).length > 0;
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

function debug(msg) {
	console.log('iosrtc-swift-support.js [INFO] ' + msg);
}

function debugerror(msg) {
	console.error('iosrtc-swift-support.js [ERROR] ' + msg);
}

// Starting here

module.exports = function (context) {
	var
		projectRoot = context.opts.projectRoot,
		projectName = getProjectName(projectRoot),
		xcconfigPath = path.join(projectRoot, '/platforms/ios/cordova/build.xcconfig'),
		xcodeProjectName = projectName + '.xcodeproj',
		xcodeProjectPath = path.join(projectRoot, 'platforms', 'ios', xcodeProjectName, 'project.pbxproj'),
		swiftBridgingHead = projectName + BRIDGING_HEADER_END,
		swiftBridgingHeadXcode = '"' + swiftBridgingHead + '"',
		swiftOptions = [''], // <-- begin to file appending AFTER initial newline
		xcodeProject;

	// Showing info about the tasks to do
	debug('cordova-plugin-iosrtc is checking issues in the generated project files:');
	debug('- Minimum "iOS Deployment Target" and "Deployment Target" to: ' + IPHONEOS_DEPLOYMENT_TARGET_XCODE);
	debug('- "Runpath Search Paths" to: ' + RUNPATH_SEARCH_PATHS_XCODE);
	debug('- "Objective-C Bridging Header" to: ' + swiftBridgingHeadXcode);
	debug('- "ENABLE_BITCODE" set to: ' + ENABLE_BITCODE_XCODE);
	debug('- "SWIFT_VERSION" set to: ' + SWIFT_VERSION_XCODE);

	// Checking if the project files are in the right place
	if (!fs.existsSync(xcodeProjectPath)) {
		debugerror('an error occurred searching the project file at: "' + xcodeProjectPath + '"');

		return;
	}
	debug('".pbxproj" project file found: ' + getRelativeToProjectRootPath(xcodeProjectPath, projectRoot));

	if (!fs.existsSync(xcconfigPath)) {
		debugerror('an error occurred searching the project file at: "' + xcconfigPath + '"');

		return;
	}
	debug('".xcconfig" project file found: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));

	xcodeProject = xcode.project(xcodeProjectPath);

	// Massaging the files
	
	// "build.xcconfig"
	debug('checking file: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));
	var xcconfigPathChanged = false;

	// Parsing it
	var currentSwiftOptions = [];
	if (fs.existsSync(xcconfigPath)) {
		currentSwiftOptions = fs.readFileSync(xcconfigPath).toString().split("\n");
	}

	if (!matchXcconfigPathValue(currentSwiftOptions, 'LD_RUNPATH_SEARCH_PATHS', RUNPATH_SEARCH_PATHS)) {
		swiftOptions.push('LD_RUNPATH_SEARCH_PATHS = ' + RUNPATH_SEARCH_PATHS);
		xcconfigPathChanged = true;
	}

	if (!matchXcconfigPathValue(currentSwiftOptions, 'SWIFT_OBJC_BRIDGING_HEADER', swiftBridgingHead)) {
		swiftOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + swiftBridgingHead);
		xcconfigPathChanged = true;
	}

	if (!matchXcconfigMinValue(currentSwiftOptions, 'IPHONEOS_DEPLOYMENT_TARGET', IPHONEOS_DEPLOYMENT_TARGET)) {
		swiftOptions.push('IPHONEOS_DEPLOYMENT_TARGET = ' + IPHONEOS_DEPLOYMENT_TARGET);
		xcconfigPathChanged = true;
	}

	if (!matchXcconfigPathValue(currentSwiftOptions, 'ENABLE_BITCODE', ENABLE_BITCODE)) {
		swiftOptions.push('ENABLE_BITCODE = ' + ENABLE_BITCODE);
		xcconfigPathChanged = true;
	}

	if (!matchXcconfigPathValue(currentSwiftOptions, 'SWIFT_VERSION', SWIFT_VERSION)) {
		swiftOptions.push('SWIFT_VERSION = ' + SWIFT_VERSION);
		xcconfigPathChanged = true;
	}

	// NOTE: Not needed
	// swiftOptions.push('EMBEDDED_CONTENT_CONTAINS_SWIFT = YES');
	
	if (xcconfigPathChanged) {
		fs.appendFileSync(xcconfigPath, swiftOptions.join('\n'));
		debug('file correctly fixed: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));
	} else {
		debug('file is correct: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));
	}

	// "project.pbxproj"
	debug('checking file: ' + getRelativeToProjectRootPath(xcodeProjectPath, projectRoot));	

	// Parsing it
	xcodeProject.parse(function (error) {

		if (error) {
			debugerror('an error occurred during the parsing of the project file: ' + xcodeProjectPath);
			return;
		}

		// Adding or changing the parameters only if we need
		var buildSettingsChanged = false;
		var configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
		Object.keys(configurations).forEach(function (config) {
			var buildSettings = configurations[config].buildSettings;

			// TODO check compatibilityVersion once on Cordova 5+

			if (!hasBuildSettingsValue(buildSettings.LD_RUNPATH_SEARCH_PATHS, RUNPATH_SEARCH_PATHS_XCODE)) {
				buildSettings.LD_RUNPATH_SEARCH_PATHS = RUNPATH_SEARCH_PATHS_XCODE;
				buildSettingsChanged = true;
			}

			if (!hasBuildSettingsValue(buildSettings.SWIFT_OBJC_BRIDGING_HEADER, swiftBridgingHeadXcode)) {
				buildSettings.SWIFT_OBJC_BRIDGING_HEADER = swiftBridgingHeadXcode;	
				buildSettingsChanged = true;
			}

			if (!matchBuildSettingsMinValue(buildSettings.IPHONEOS_DEPLOYMENT_TARGET, IPHONEOS_DEPLOYMENT_TARGET_XCODE)) {
				buildSettings.IPHONEOS_DEPLOYMENT_TARGET = IPHONEOS_DEPLOYMENT_TARGET_XCODE;
				buildSettingsChanged = true;				
			}

			if (!matchBuildSettingsValue(buildSettings.ENABLE_BITCODE, ENABLE_BITCODE_XCODE)) {
				buildSettings.ENABLE_BITCODE = ENABLE_BITCODE_XCODE;
				buildSettingsChanged = true;
			}

			if (!matchBuildSettingsValue(buildSettings.SWIFT_VERSION, SWIFT_VERSION_XCODE)) {
				buildSettings.SWIFT_VERSION = SWIFT_VERSION_XCODE;
				buildSettingsChanged = true;
			}
		});

		// Writing the file only if changed
		if (buildSettingsChanged) {
			fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), 'utf-8');
			debug('file correctly fixed: ' + getRelativeToProjectRootPath(xcodeProjectPath, projectRoot));	
		} else {
			debug('file is correct: ' + getRelativeToProjectRootPath(xcodeProjectPath, projectRoot));	
		}
	});
};
