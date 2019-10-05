import Foundation
import AVFoundation

import func ObjectiveC.objc_getAssociatedObject
import func ObjectiveC.objc_setAssociatedObject
import enum ObjectiveC.objc_AssociationPolicy

public func objc_getx<TargetObject: AnyObject, AssociatedObject: AnyObject>
	(object getObject: @autoclosure () -> AssociatedObject,
	 associatedTo target:TargetObject,
	 withConstPtrKey ptr:UnsafeRawPointer)
	-> AssociatedObject
{
	var object = objc_getAssociatedObject(target, ptr) as? AssociatedObject
	if object == nil {
		object = getObject()
		objc_setAssociatedObject(target, ptr, object, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	return object!
}

/* Expose videoCaptureController on RTCMediaStreamTrack */
extension RTCMediaStreamTrack {
	
	class PropClass {
		var videoCaptureController: PluginRTCVideoCaptureController?
	}
	
	var _propClass : PropClass {
		get {
			let key: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern:self.hashValue)
			return objc_getx(object: PropClass(), associatedTo: self, withConstPtrKey: key)
		}
	}
	
	var videoCaptureController: PluginRTCVideoCaptureController? {
		get {
			return _propClass.videoCaptureController
		}
		set {
			_propClass.videoCaptureController = newValue
		}
	}
}

class PluginRTCVideoCaptureController : NSObject {
	
	var capturer: RTCCameraVideoCapturer
	
	// Default to the front camera.
	var usingFrontCamera: Bool = true
	var deviceId: String = ""
	var targetFrameRate: Int32 = 30
	
	init(capturer: RTCCameraVideoCapturer) {
		self.capturer = capturer
	}
	
	/*
	// See: https://www.w3.org/TR/mediacapture-streams/#media-track-constraints
	dictionary MediaTrackConstraintSet {
	 ConstrainULong     width;
	 ConstrainULong     height;
	 ConstrainDouble    aspectRatio;
	 ConstrainDouble    frameRate;
	 ConstrainDOMString facingMode;
	 ConstrainDOMString resizeMode;
	 ConstrainULong     sampleRate;
	 ConstrainULong     sampleSize;
	 ConstrainBoolean   echoCancellation;
	 ConstrainBoolean   autoGainControl;
	 ConstrainBoolean   noiseSuppression;
	 ConstrainDouble    latency;
	 ConstrainULong     channelCount;
	 ConstrainDOMString deviceId;
	 ConstrainDOMString groupId;
	};
	 
	 // typedef ([Clamp] unsigned long or ConstrainULongRange) ConstrainULong;
	 dictionary ULongRange {
		[Clamp] unsigned long max;
		[Clamp] unsigned long min;
	 };

	 dictionary ConstrainULongRange : ULongRange {
		  [Clamp] unsigned long exact;
		  [Clamp] unsigned long ideal;
	 };
	 
	 // See: https://www.w3.org/TR/mediacapture-streams/#dom-doublerange
	 // typedef (double or ConstrainDoubleRange) ConstrainDouble;
	 dictionary DoubleRange {
		double max;
		double min;
	 };
	 
	 dictionary ConstrainDoubleRange : DoubleRange {
		double exact;
		double ideal;
	 };
	 
	 // typedef (boolean or ConstrainBooleanParameters) ConstrainBoolean;
	 dictionary ConstrainBooleanParameters {
		boolean exact;
		boolean ideal;
	 };
	 
	 // typedef (DOMString or sequence<DOMString> or ConstrainDOMStringParameters) ConstrainDOMString;
	 dictionary ConstrainDOMStringParameters {
		(DOMString or sequence<DOMString>) exact;
		(DOMString or sequence<DOMString>) ideal;
	 };
	*/
	func setConstraints(constraints: NSDictionary) {
		
		// TODO facingMode ConstrainDOMString NSDictionary
		// TODO check deviceId
		// Check the video contraints: examine facingMode and deviceId
		// and pick a default if neither are specified.
		let facingMode = constraints.object(forKey: "facingMode") as? String ?? ""
		if (facingMode.count > 0) {
			var position: AVCaptureDevice.Position
			if (facingMode == "environment") {
				position = AVCaptureDevice.Position.back
			} else if (facingMode == "user") {
				position = AVCaptureDevice.Position.front
			} else {
				// If the specified facingMode value is not supported, fall back
				// to the front camera.
				position = AVCaptureDevice.Position.front
			}
			
			self.usingFrontCamera = (position == AVCaptureDevice.Position.front)
		}
		
		// TODO deviceId ConstrainDOMString NSDictionary
		self.deviceId = constraints.object(forKey: "deviceId") as? String ?? ""
		
		// TODO ConstrainULong NSDictionary for width, height
		
		// TODO ConstrainDouble NSDictionary for frameRate, aspectRatio
	}
	
	func startCapture() {
		var device: AVCaptureDevice?

		if (self.deviceId.count > 0) {
			device = AVCaptureDevice(uniqueID: self.deviceId)
			if (!device!.isConnected) {
				device = nil
			}
		}

		if (device == nil) {
			let position: AVCaptureDevice.Position = (self.usingFrontCamera) ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
			device = findDeviceForPosition(position: position);
		}
		
		// TODO: Extract width and height from constraints.
		let format = selectFormatForDevice(device:device!)
		if (format == nil) {
			NSLog("PluginRTCVideoCaptureController#startCapture No valid formats for device %@", device!);
			return
		}
		
		// TODO: Extract fps from constraints.
		// TODO: completionHandler
		self.capturer.startCapture(
			with: device!,
			format: format!,
			fps: Int(self.targetFrameRate)
		)
		
		NSLog("PluginRTCVideoCaptureController#startCapture Capture started, device:%@, format:%@", device!, format!);
	}
	
	func stopCapture() {
		// TODO: map to RTCMediaStreamTrack stop if has videoCaptureController
		// TODO: stopCaptureWithCompletionHandler
		self.capturer.stopCapture()
		
		NSLog("PluginRTCVideoCaptureController#stopCapture Capture stopped");
	}
	
	func switchCamera() {
		self.usingFrontCamera = !self.usingFrontCamera;
		
		self.startCapture()
	}
	
	func findDeviceForPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
		let captureDevices: NSArray = RTCCameraVideoCapturer.captureDevices() as NSArray
		for device: Any in captureDevices {
			let avDevice = device as! AVCaptureDevice
			if (avDevice.position == position) {
				return avDevice
			}
		}
	
		// TODO fail on no match ?
		return captureDevices[0] as? AVCaptureDevice
	}
	
	func selectFormatForDevice(device: AVCaptureDevice) -> AVCaptureDevice.Format? {
		
		var selectedFormat: AVCaptureDevice.Format? = nil
		let formats: NSArray = RTCCameraVideoCapturer.supportedFormats(for: device) as NSArray
		for format: Any in formats {
			
			let devFormat: AVCaptureDevice.Format = format as! AVCaptureDevice.Format
			let pixelFormat: FourCharCode = CMFormatDescriptionGetMediaSubType(devFormat.formatDescription)
			// TODO ConstrainULong height/width
			//let dimension: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(devFormat.formatDescription)
		  
			if (pixelFormat == self.capturer.preferredOutputPixelFormat()) {
				selectedFormat = devFormat
			}
		}
	
		return selectedFormat
	}
}
