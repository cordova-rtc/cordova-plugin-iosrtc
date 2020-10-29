/*
 * cordova-plugin-iosrtc v6.0.16
 * Cordova iOS plugin exposing the full WebRTC W3C JavaScript APIs
 * Copyright 2015-2017 eFace2Face, Inc. (https://eface2face.com)
 * Copyright 2015-2019 BasqueVoIPMafia (https://github.com/BasqueVoIPMafia)
 * Copyright 2017-2020 Cordova-RTC (https://github.com/cordova-rtc)
 * License MIT
 */

(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.androidrtc = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(_dereq_,module,exports){
var exec = _dereq_('cordova/exec');
var deviceChangesListenerIsAdded = false;

module.exports = {
    getEnumerateDevices: getEnumerateDevices,
};

function getEnumerateDevices(arg0, success, error) {

    if(!deviceChangesListenerIsAdded){
        console.log("Adding devicechange listener");
        addDeviceChangeListener();
        exec(success, error, 'EnumerateDevicesPlugin', 'addDeviceListener', [arg0]);
        deviceChangesListenerIsAdded = true;
    }

    var isPromise, callback;
    if (typeof arguments[0] !== 'function') {
        isPromise = true;
    } else {
        isPromise = false;
        callback = arguments[0];
    }

    if (isPromise) {
        return new Promise(function(resolve) {
            function onResultOK(devices) {
                console.info('enumerateDevices() | success');
                resolve(getMediaDeviceInfos(devices));
            }
            exec(onResultOK, error, 'EnumerateDevicesPlugin', 'enumerateDevices', [arg0]);
        });
    }

    function onResultOK(devices) {
        console.info('enumerateDevices() | success');
        callback(getMediaDeviceInfos(devices));
    }
    exec(onResultOK, error, 'EnumerateDevicesPlugin', 'enumerateDevices', [arg0]);
}

/**
 * Private API
 */

function addDeviceChangeListener() {
    navigator.mediaDevices.addEventListener('devicechange', navigator.mediaDevices.ondevicechange);
}

function getMediaDeviceInfos(devices) {
    console.info('getMediaDeviceInfos() ', devices);

    var id,
        mediaDeviceInfos = [];

    for (id in devices) {
        if (devices.hasOwnProperty(id)) {
            mediaDeviceInfos.push(mediaDeviceInfo(devices[id]));
        }
    }

    return devices;
}

function mediaDeviceInfo(data) {
    data = data || {};

    return {
        // MediaDeviceInfo spec.
        deviceId: {
            value: data.deviceId,
        },
        kind: {
            value: data.kind,
        },
        label: {
            value: data.label,
        },
        groupId: {
            value: data.groupId || '',
        },
    };
}
},{"cordova/exec":undefined}]},{},[1])(1)
});
