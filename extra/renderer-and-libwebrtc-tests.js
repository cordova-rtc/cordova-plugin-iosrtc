/* global RTCPeerConnection */

//
// Camera and Microphone Authorization   
//

/*
cordova.plugins.diagnostic.requestMicrophoneAuthorization(function (status) {
    if(status === cordova.plugins.diagnostic.permissionStatus.GRANTED) {
        console.log('GRANTED');
    } else {
        console.log(new Error('AuthorizationDenied'));   
    }
}, function (err) {
    console.log(new Error('AuthorizationFailed: ' + err));   
});

cordova.plugins.diagnostic.requestCameraAuthorization(function (status) {
    if(status === cordova.plugins.diagnostic.permissionStatus.GRANTED) {
        console.log('GRANTED');
    } else {
        console.log(new Error('AuthorizationDenied'));   
    }
}, function (err) {
    console.log(new Error('AuthorizationFailed: ' + err));   
});
*/

var cordova = window.cordova;

// Expose WebRTC Globals
if (cordova && cordova.plugins && cordova.plugins.iosrtc) {
  cordova.plugins.iosrtc.registerGlobals();
  cordova.plugins.iosrtc.debug.enabled = true;
}


//
// Container
//

document.body.innerHTML = "";
var appContainer = document.body;

//
// getUserMedia
//

var localStream;
function TestGetUserMedia() {

  var localVideoEl = document.createElement('video');
  localVideoEl.setAttribute('autoplay', 'autoplay');
  localVideoEl.setAttribute('playsinline', 'playsinline');
  // Cause zIndex - 1 failure
  //localVideoEl.style.backgroundColor = 'purple';
  localVideoEl.style.position = 'absolute';
  localVideoEl.style.top = 0;
  localVideoEl.style.left = 0;
  localVideoEl.style.width = "100px";
  localVideoEl.style.height = "100px";
  localVideoEl.style.transform = "scaleX(-1)";
  appContainer.appendChild(localVideoEl);

  navigator.mediaDevices.enumerateDevices().then(function (devices) {
      console.log('getMediaDevices.ok', devices);
      devices.forEach(function (device, idx) {
        console.log('getMediaDevices.devices', idx, device.label, device.kind, device.deviceId);
      });
  }, function (err) {
      console.log('getMediaDevices.err', err);
  });

  navigator.mediaDevices.getUserMedia({
    video: true,
    audio: true
    /*
    video: {
      // Test Back Camera
      //deviceId: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      //sourceId: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      deviceId: {
        exact: 'com.apple.avfoundation.avcapturedevice.built-in_video:0'
      }
    }, 
    audio: {
      exact: 'Built-In Microphone'
    }*/
  }).then(function (stream) {

    console.log('getUserMedia.stream', stream);
    console.log('getUserMedia.stream.getTracks', stream.getTracks());

    var srcObjectStream;
    try {

      localStream = stream;
      srcObjectStream = localVideoEl.srcObject = localStream;
      //localVideoEl.src = window.URL.createObjectURL(stream);
    
    } catch (err) {
      console.log('srcObject.err', err);
    }

    if (cordova && cordova.plugins && cordova.plugins.iosrtc) {
      cordova.plugins.iosrtc.observeVideo(localVideoEl);
    }

    if (srcObjectStream) {

      TestPluginMediaStreamRenderer(localVideoEl);
      TestRTCPeerConnection(localStream); 
    }
   
  }).catch(function (err) {
    console.log('getUserMediaError', err, err.stack);
  });
}

var useAnimateVideo = false;
function TestPluginMediaStreamRenderer(localVideoEl) {

  // Animate video position
  var currentPosition = {
    x: 0,
    y: 0
  };

  var animateTimer;
  function animateVideo() {
    
    currentPosition.x = currentPosition.x < (window.innerWidth - parseInt(localVideoEl.style.width, 10)) ? currentPosition.x + 1 : 0;
    currentPosition.y = currentPosition.y < (window.innerHeight - parseInt(localVideoEl.style.height, 10)) ? currentPosition.y + 1 : 0;

    localVideoEl.style.top = currentPosition.y + 'px';
    localVideoEl.style.left = currentPosition.x + 'px';

    if (cordova && cordova.plugins && cordova.plugins.iosrtc) {
      cordova.plugins.iosrtc.refreshVideos();
    }

    return (animateTimer = requestAnimationFrame(animateVideo));
  }

  if (useAnimateVideo) {
    animateTimer = animateVideo(); 
  }

  //
  // Test Video behind Element
  //

  document.body.style.background = "transparent";
  document.documentElement.style.background = "transparent";
  localVideoEl.style.zIndex = -1;

  var overEl = document.createElement('button');
  overEl.style.backgroundColor = 'red';
  overEl.style.position = 'absolute';
  overEl.style.left = 0;
  overEl.style.top = 0;
  overEl.style.width = "100px";
  overEl.style.height = "100px";

  overEl.addEventListener('click', function () {
    overEl.style.backgroundColor = overEl.style.backgroundColor === 'red' ? 'green' : 'red';

    if (overEl.style.backgroundColor === 'red') {
      animateTimer = animateVideo();
    } else {
      cancelAnimationFrame(animateTimer);
    }
  });

  appContainer.appendChild(overEl);

  overEl.style.left = ((window.innerWidth / 2)  - parseInt(overEl.style.width, 10)) + 'px';
  overEl.style.top  = ((window.innerHeight / 2) - parseInt(overEl.style.height, 10)) + 'px';

}

//
// Test RTCPeerConnection
// 


var pc1 = new RTCPeerConnection(),
    pc2 = new RTCPeerConnection();

function TestRTCPeerConnection(localStream) {

  // TODO Deprecated
  //pc1.addStream(localStream);

  // To Test removeStream
  // pc1.removeStream(pc1.getLocalStreams()[0])

  // TODO
  // NotSupportedError: The adapter.js addTrack polyfill only supports a single stream which is associated with the specified track.
  localStream.getTracks().forEach(function (track) {
    console.log('addTrack', track);
    pc1.addTrack(track);
  });
  
  function onAddIceCandidate(pc, can) {
    console.log('onAddIceCandidate', pc, can);
    return can && pc.addIceCandidate(can).catch(function (err) {
      console.log('addIceCandidateError', err);
    });
  }

  pc1.onicecandidate = function (e) {
    onAddIceCandidate(pc2, e.candidate);
  };
  pc2.onicecandidate = function (e) {
    onAddIceCandidate(pc1, e.candidate);
  };

  pc2.onaddstream = function (e) {
    console.log('pc2.onAddStream', e);

    var peerVideoEl = document.createElement('video');
    peerVideoEl.setAttribute('autoplay', 'autoplay');
    peerVideoEl.setAttribute('playsinline', 'playsinline');
    peerVideoEl.style.backgroundColor = 'blue';
    peerVideoEl.style.position = 'fixed';
    peerVideoEl.style.width = "100px";
    peerVideoEl.style.height = "100px";
    peerVideoEl.style.top = 0;
    peerVideoEl.style.left = (window.innerWidth - parseInt(peerVideoEl.style.width, 10)) + 'px';
    appContainer.appendChild(peerVideoEl);

    peerVideoEl.srcObject = e.stream;

    if (cordova && cordova.plugins && cordova.plugins.iosrtc) {
      cordova.plugins.iosrtc.observeVideo(peerVideoEl);
    }
  };

  pc1.oniceconnectionstatechange = function (e) {
    console.log('pc1.iceConnectionState', e, pc1.iceConnectionState);

    if (pc1.iceConnectionState === 'completed') {      
      console.log('pc1.getSenders', pc1.getSenders());
      console.log('pc2.getReceivers', pc2.getReceivers());
    }
  };

  pc1.onnegotiationneeded = function (e) {
    console.log('pc1.negotiatioNeeded', e);

    return pc1.createOffer().then(function (d) {
      return pc1.setLocalDescription(d);
    }).then(function () {
      return pc2.setRemoteDescription({
        type: pc1.localDescription.type,
        sdp: pc1.localDescription.sdp
      });
    }).then(function () {
      return pc2.createAnswer();
    }).then(function (d) {
      return pc2.setLocalDescription(d);
    }).then(function () {
      return pc1.setRemoteDescription({
        type: pc2.localDescription.type,
        sdp: pc2.localDescription.sdp
      });
    }).catch(function (err) {
      console.log('pc1.createOfferError', err);
    });
  };
}

var useWebRTCAdapter = false;

// Expose webrtc-adapter
if (useWebRTCAdapter && typeof window.adapter === 'undefined') {

    // load adapter.js
    var version = 'latest';
    var script = document.createElement("script");
    script.type = "text/javascript";
    //script.src = "adapter-latest.js";
    script.src = "https://webrtc.github.io/adapter/adapter-" + version + ".js";
    script.async = false;
    document.getElementsByTagName("head")[0].appendChild(script);
    script.onload = function () {
      console.log('useWebRTCAdapter.loaded', script.src);
      TestGetUserMedia();
    };
} else {
  TestGetUserMedia();
}



