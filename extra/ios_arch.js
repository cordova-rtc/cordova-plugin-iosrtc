#!/usr/bin/env node

/*jshint esversion: 6 */
'use strict';

const os = require('os');
const fs = require('fs');
const path = require('path');
const exec = require('child_process').execSync;

const LIB_PATH = path.join(__dirname, '../lib');
const WEBRTC_LIB_PATH = path.join(LIB_PATH, 'WebRTC.framework');
const WEBRTC_XC_LIB_PATH = path.join(LIB_PATH, 'WebRTC.xcframework');

const TMP_PATH = os.tmpdir();
const WEBRTC_SIM_LIB_PATH = path.join(TMP_PATH, '/sim/WebRTC.framework');
const WEBRTC_DEVICE_LIB_PATH = path.join(TMP_PATH, '/device/WebRTC.framework');

const ARCH_SIM_TYPES = ['i386', 'x86_64'];
const ARCH_DEVICE_TYPES = ['armv7', 'arm64'];
const ARCH_TYPES = ARCH_SIM_TYPES.concat(ARCH_DEVICE_TYPES);

/* === Example to strip simulator archs for Apple Store Submission ===
 *
 * Step 1. extract all archs first
 *    `node ios_arch.js --extract`
 * Step 2. re-package binary without simulator archs
 *    `node ios_arch.js --device`
 *
 * That's it!
 * Remember to delete generated/backed up files (WebRTC-*) from step 1 if needed
 *
 * === How to Verify ===
 *
 * You can check current archs use this command:
 *     `file $YOUR_PATH/WebRTC.framework/WebRTC`
 */

function extractArchitecture(archs, cwd) {
	archs.forEach((arch) => {
		//console.log(`lipo -extract ${arch} WebRTC -o WebRTC-${arch}`, cwd);
		exec(`lipo -extract ${arch} WebRTC -o WebRTC-${arch}`, { cwd: cwd });
	});
}

function exportArchitecture(archs, cwd) {
	exec(
		`lipo -o WebRTC -create ${archs
			.map(function (arch) {
				return `WebRTC-${arch}`;
			})
			.join(' ')}`,
		{ cwd: cwd }
	);
}

if (process.argv[2] === '--extract' || process.argv[2] === '-e') {
	console.log('Extracting...');
	// extract all archs, you might want to delete it later.
	extractArchitecture(ARCH_TYPES, WEBRTC_LIB_PATH);
	exec('cp WebRTC WebRTC-all', { cwd: WEBRTC_LIB_PATH }); // make a backup
} else if (process.argv[2] === '--simulator' || process.argv[2] === '-s') {
	// re-package simulator related archs only. ( i386, x86_64 )
	console.log('Compiling simulator...');
	exportArchitecture(ARCH_SIM_TYPES, WEBRTC_LIB_PATH);
} else if (process.argv[2] === '--device' || process.argv[2] === '-d') {
	// re-package device related archs only. ( armv7, arm64 )
	console.log('Compiling device...');
	exportArchitecture(ARCH_DEVICE_TYPES, WEBRTC_LIB_PATH);
} else if (process.argv[2] === '--xcframework' || process.argv[2] === '-x') {
	// extract all archs, you might want to delete it later.
	extractArchitecture(ARCH_TYPES, WEBRTC_LIB_PATH);

	// xcframework
	console.log('Generating WebRTC.framework for device...');
	fs.mkdirSync(WEBRTC_DEVICE_LIB_PATH, { recursive: true });
	exec(`cp -r 'WebRTC.framework/'* '${WEBRTC_DEVICE_LIB_PATH}'`, { cwd: LIB_PATH });
	exportArchitecture(ARCH_DEVICE_TYPES, WEBRTC_DEVICE_LIB_PATH);
	exec(`rm -f WebRTC-*`, { cwd: WEBRTC_DEVICE_LIB_PATH });

	console.log('Generating WebRTC.framework for simulator...');
	fs.mkdirSync(WEBRTC_SIM_LIB_PATH, { recursive: true });
	exec(`cp -r 'WebRTC.framework/'* '${WEBRTC_SIM_LIB_PATH}'`, { cwd: LIB_PATH });
	exportArchitecture(ARCH_SIM_TYPES, WEBRTC_SIM_LIB_PATH);
	exec(`rm -f WebRTC-*`, { cwd: WEBRTC_SIM_LIB_PATH });

	console.log('Generating WebRTC.xcframework...');
	exec(`rm -rf ${WEBRTC_XC_LIB_PATH}`, { cwd: LIB_PATH });

	exec(
		`xcodebuild -create-xcframework -framework ${WEBRTC_DEVICE_LIB_PATH} -framework ${WEBRTC_SIM_LIB_PATH} -output '${WEBRTC_XC_LIB_PATH}'`,
		{ cwd: LIB_PATH }
	);

	exec(`rm -f WebRTC-*`, { cwd: WEBRTC_LIB_PATH });
	exec(`rm -fr ${WEBRTC_DEVICE_LIB_PATH}`, { cwd: TMP_PATH });
	exec(`rm -fr ${WEBRTC_SIM_LIB_PATH}`, { cwd: TMP_PATH });
} else if (process.argv[2] === '--list' || process.argv[2] === '-l') {
	// List WebRTC architectures
	console.log('List WebRTC architectures...');
	console.log(exec(`file WebRTC`, { cwd: WEBRTC_LIB_PATH }).toString().trim());
} else if (process.argv[2] === '--clean' || process.argv[2] === '-l') {
	// Delete WebRTC-* architectures
	console.log('Clean WebRTC architectures...');
	exec(`rm -f WebRTC-*`, { cwd: WEBRTC_LIB_PATH });
} else {
	console.log('Unknow options');
}

console.log('List WebRTC files...');
console.log(exec('ls -ahl | grep WebRTC', { cwd: LIB_PATH }).toString().trim());
