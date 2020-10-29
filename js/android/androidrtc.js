var exec = require('cordova/exec');
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