#!/usr/bin/env node

'use strict';

// This hook automates this:
// https://github.com/cordova-rtc/cordova-plugin-iosrtc/blob/master/docs/Building.md

var
	fs = require("fs"),
	path = require("path"),
	xcode = require('xcode'),
	xmlEntities = new (require('html-entities').XmlEntities)(),

	IPHONEOS_DEPLOYMENT_TARGET = '10.2',
	IPHONEOS_DEPLOYMENT_TARGET_XCODE = '"' + IPHONEOS_DEPLOYMENT_TARGET + '"',
	SWIFT_VERSION = '4.2',
	SWIFT_VERSION_XCODE = '"' + SWIFT_VERSION + '"',
	RUNPATH_SEARCH_PATHS = '@executable_path/Frameworks',
	RUNPATH_SEARCH_PATHS_XCODE = '"' + RUNPATH_SEARCH_PATHS + '"',
	ENABLE_BITCODE = 'NO',
	ENABLE_BITCODE_XCODE = '"' + ENABLE_BITCODE + '"',
	UNIFIED_BRIDGING_HEADER = 'Plugins/Unified-Bridging-Header.h',
	IOSRTC_BRIDGING_HEADER = "cordova-plugin-iosrtc-Bridging-Header.h",
	BRIDGING_HEADER_END = '/Plugins/cordova-plugin-iosrtc/' + IOSRTC_BRIDGING_HEADER,
	TEST_UNIFIED_BRIDGING_HEADER = false; // Set to true to test handling of existing swift bridging header

// Helpers

// Returns the project name
function getProjectName(protoPath) {
	var
		cordovaConfigPath = path.join(protoPath, 'config.xml'),
		content = fs.readFileSync(cordovaConfigPath, 'utf-8');

	var name = /<name>([\s\S]*)<\/name>/mi.exec(content)[1].trim();
	return xmlEntities.decode(name);
}

// Drops the comments
var COMMENT_KEY = /_comment$/;
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
	return parseFloat(value.replace(/[^\d.-]/g,''), 10);
}

function matchMinValue(value, minValue) {
	//console.log('matchMinValue', value, minValue)
	return value && convertToFloat(value) >= convertToFloat(minValue);
}

function matchBuildSettingsMinValue(value, expectedValue) {
	return value && (matchBuildSettingsValue(value, expectedValue) || matchMinValue(value, expectedValue));
}

function matchXcconfigPathValue(swiftOptions, path, expectedValue) {
	return swiftOptions.filter(function (swiftOption) {
		return swiftOption === path + ' = ' + expectedValue;
	}).length > 0;
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
	return fs.readFileSync(filePath).toString().split("\n");
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

	// This script has to be executed depending on the command line arguments, not
  	// on the hook execution cycle.
  	/*
	if (context.hook !== 'before_build' && !context.cmdLine.includes('build')) {
		return;
	}
	*/

	var
		projectRoot = context.opts.projectRoot,
		projectName = getProjectName(projectRoot),
		platformPath = path.join(projectRoot, 'platforms', 'ios'),
		platformProjectPath = path.join(platformPath, projectName),
		xcconfigPath = path.join(platformPath, '/cordova/build.xcconfig'),
		xcodeProjectName = projectName + '.xcodeproj',
		xcodeProjectConfigPath = path.join(platformPath, xcodeProjectName, 'project.pbxproj'),
		swiftBridgingHeaderPath = projectName + BRIDGING_HEADER_END,
		swiftBridgingHeaderPathXcode = '"' + swiftBridgingHeaderPath + '"',
		swiftOptions = [''], // <-- begin to file appending AFTER initial newline
		xcodeProject;

	// Showing info about the tasks to do
	debug('cordova-plugin-iosrtc is checking issues in the generated project files:');
	debug('- Minimum "iOS Deployment Target" and "Deployment Target" to: ' + IPHONEOS_DEPLOYMENT_TARGET_XCODE);
	debug('- "Runpath Search Paths" to: ' + RUNPATH_SEARCH_PATHS_XCODE);
	if (TEST_UNIFIED_BRIDGING_HEADER) {
		debug('- "Objective-C Bridging Header" to: ' + UNIFIED_BRIDGING_HEADER);
	} else {
		debug('- "Objective-C Bridging Header" to: ' + swiftBridgingHeaderPathXcode);
	}
	debug('- "ENABLE_BITCODE" set to: ' + ENABLE_BITCODE_XCODE);
	debug('- "SWIFT_VERSION" set to: ' + SWIFT_VERSION_XCODE);

	// Checking if the project files are in the right place
	if (!fs.existsSync(xcodeProjectConfigPath)) {
		debugError('an error occurred searching the project file at: "' + xcodeProjectConfigPath + '"');

		return;
	}
	debug('".pbxproj" project file found: ' + getRelativeToProjectRootPath(xcodeProjectConfigPath, projectRoot));

	if (!fs.existsSync(xcconfigPath)) {
		debugError('an error occurred searching the project file at: "' + xcconfigPath + '"');

		return;
	}
	debug('".xcconfig" project file found: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));

	xcodeProject = xcode.project(xcodeProjectConfigPath);

	// Massaging the files
	
	// "build.xcconfig"
	debug('checking file: ' + getRelativeToProjectRootPath(xcconfigPath, projectRoot));
	var xcconfigPathChanged = false;

	// Parsing it
	var currentSwiftOptions = [];
	if (fs.existsSync(xcconfigPath)) {
		currentSwiftOptions = readFileLines(xcconfigPath);
	}

	if (!matchXcconfigPathValue(currentSwiftOptions, 'LD_RUNPATH_SEARCH_PATHS', RUNPATH_SEARCH_PATHS)) {
		swiftOptions.push('LD_RUNPATH_SEARCH_PATHS = ' + RUNPATH_SEARCH_PATHS);
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

	var existingSwiftBridgingHeaderPath;
	if (TEST_UNIFIED_BRIDGING_HEADER) {
		existingSwiftBridgingHeaderPath = path.join(platformProjectPath, UNIFIED_BRIDGING_HEADER);
	} else {
		if (!matchXcconfigPathValue(currentSwiftOptions, 'SWIFT_OBJC_BRIDGING_HEADER', swiftBridgingHeaderPath)) {
			var currentSwiftBridgingHeader = getXcconfigPathValue(currentSwiftOptions, 'SWIFT_OBJC_BRIDGING_HEADER').replace('$(PROJECT_DIR)/$(PROJECT_NAME)/', '');
			if (!existingSwiftBridgingHeaderPath) {
				swiftOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + swiftBridgingHeaderPath);
				xcconfigPathChanged = true;	
			} else {
				existingSwiftBridgingHeaderPath = path.join(platformProjectPath, currentSwiftBridgingHeader);
			}
		}	
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
	debug('checking file: ' + getRelativeToProjectRootPath(xcodeProjectConfigPath, projectRoot));	

	// Parsing it
	xcodeProject.parse(function (error) {

		if (error) {
			debugError('an error occurred during the parsing of the project file: ' + xcodeProjectConfigPath);

			return;
		}

		// Adding or changing the parameters only if we need
		var buildSettingsChanged = false;
		var hasSwiftBridgingHeaderPathXcodes = []; 
		var configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
		Object.keys(configurations).forEach(function (config) {
			var buildSettings = configurations[config].buildSettings;

			if (!hasBuildSettingsValue(buildSettings.LD_RUNPATH_SEARCH_PATHS, RUNPATH_SEARCH_PATHS_XCODE)) {
				buildSettings.LD_RUNPATH_SEARCH_PATHS = RUNPATH_SEARCH_PATHS_XCODE;
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

			if (TEST_UNIFIED_BRIDGING_HEADER) {
				buildSettings.SWIFT_OBJC_BRIDGING_HEADER = '"' + UNIFIED_BRIDGING_HEADER + '"';
				xcodeProject.addHeaderFile(UNIFIED_BRIDGING_HEADER);
			}

			if (!hasBuildSettingsValue(buildSettings.SWIFT_OBJC_BRIDGING_HEADER, swiftBridgingHeaderPathXcode)) {	

				// Play nice with existing Swift Bridging Header value
				if (existingSwiftBridgingHeaderPath) {	
					
					// Sync SWIFT_OBJC_BRIDGING_HEADER with existingSwiftBridgingHeaderPath if do not match
					var existingSwiftBridgingHeaderPathXcode = '"' + existingSwiftBridgingHeaderPath + '"';
					if (buildSettings.SWIFT_OBJC_BRIDGING_HEADER !== existingSwiftBridgingHeaderPathXcode) {
						buildSettings.SWIFT_OBJC_BRIDGING_HEADER = existingSwiftBridgingHeaderPathXcode;	
						buildSettingsChanged = true;	
					}

					if (hasSwiftBridgingHeaderPathXcodes.indexOf(existingSwiftBridgingHeaderPath) === -1) {

						// Check if existing existingSwiftBridgingHeaderPath exists and get file lines
						
						debug('checking file: ' + getRelativeToProjectRootPath(existingSwiftBridgingHeaderPath, projectRoot));

						var existingSwiftBridgingHeaderFileLines = [];
						if (fs.existsSync(existingSwiftBridgingHeaderPath)) {
							existingSwiftBridgingHeaderFileLines = readFileLines(existingSwiftBridgingHeaderPath);
						}

						// Check if existing existingSwiftBridgingHeaderFileLines contains swiftBridgingHeaderPath
						var swiftBridgingHeaderImport = '#import "' + IOSRTC_BRIDGING_HEADER + '"';
						var hasSwiftBridgingHeaderPathXcode = existingSwiftBridgingHeaderFileLines.filter(function (line) {
							return line === swiftBridgingHeaderImport;
						}).length > 0;

						if (!hasSwiftBridgingHeaderPathXcode) {
							debug('updating existing swift bridging header file: ' + getRelativeToProjectRootPath(existingSwiftBridgingHeaderPath, projectRoot));
							existingSwiftBridgingHeaderFileLines.push(swiftBridgingHeaderImport);
							fs.writeFileSync(existingSwiftBridgingHeaderPath, existingSwiftBridgingHeaderFileLines.join('\n'), 'utf-8');
							debug('file correctly fixed: ' + getRelativeToProjectRootPath(existingSwiftBridgingHeaderPath, projectRoot));	
						} else {
							debug('file is correct: ' + getRelativeToProjectRootPath(existingSwiftBridgingHeaderPath, projectRoot));
						}

						hasSwiftBridgingHeaderPathXcodes.push(existingSwiftBridgingHeaderPath);
					}


				} else {
					buildSettings.SWIFT_OBJC_BRIDGING_HEADER = swiftBridgingHeaderPathXcode;	
					buildSettingsChanged = true;	
				}
			}
		});

		// Writing the file only if changed
		if (buildSettingsChanged) {
			fs.writeFileSync(xcodeProjectConfigPath, xcodeProject.writeSync(), 'utf-8');
			debug('file correctly fixed: ' + getRelativeToProjectRootPath(xcodeProjectConfigPath, projectRoot));	
		} else {
			debug('file is correct: ' + getRelativeToProjectRootPath(xcodeProjectConfigPath, projectRoot));	
		}
	});
};
