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
	
	private let DEFAULT_HEIGHT : Int = 480
	private let DEFAULT_WIDTH : Int = 640
	private let DEFAULT_FPS : Int = 15
	
	var capturer: RTCCameraVideoCapturer
	
	// Default to the front camera.
	var device: AVCaptureDevice?
	var deviceFormat: AVCaptureDevice.Format?
	var deviceFrameRate: Int?
	
	var constraints: NSDictionary = [:]
	
	init(capturer: RTCCameraVideoCapturer) {
		self.capturer = capturer
	}
	
	/*
	// See: https://www.w3.org/TR/mediacapture-streams/#media-track-constraints
	dictionary MediaTrackConstraintSet {
	 // Supported
	 ConstrainDOMString deviceId;
	 ConstrainDOMString facingMode;
	 ConstrainULong     width;
	 ConstrainULong     height;
	 ConstrainDouble    aspectRatio;
	 ConstrainDouble    frameRate;
	 ConstrainULong     sampleRate;
	 // Not Supported
	 ConstrainDOMString resizeMode;
	 ConstrainULong     sampleSize;
	 ConstrainBoolean   echoCancellation;
	 ConstrainBoolean   autoGainControl;
	 ConstrainBoolean   noiseSuppression;
	 ConstrainDouble    latency;
	 ConstrainULong     channelCount;
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
	func setConstraints(constraints: NSDictionary) -> Bool {
		
		self.constraints = constraints;
		
		self.device = findDevice()
		
		return device != nil;
	}
	
	func startCapture() -> Bool {
		
		if (device == nil) {
			NSLog("PluginRTCVideoCaptureController#startCapture No matching device found for constraints %@", constraints);
			return false;
		}
		
		if (deviceFormat == nil) {
			NSLog("PluginRTCVideoCaptureController#startCapture No valid formats for device %@", device!);
			return false;
		}
		
		// TODO: Extract fps from constraints.
		// TODO: completionHandler
		self.capturer.startCapture(
			with: device!,
			format: deviceFormat!,
			fps: deviceFrameRate!
		)
		
		NSLog("PluginRTCVideoCaptureController#startCapture Capture started, device:%@, format:%@", device!, deviceFormat!);
		
		return true;
	}
	
	func stopCapture() {
		// TODO: map to RTCMediaStreamTrack stop if has videoCaptureController
		// TODO: stopCaptureWithCompletionHandler
		self.capturer.stopCapture()
		
		NSLog("PluginRTCVideoCaptureController#stopCapture Capture stopped");
	}
	
	fileprivate func findDevice() -> AVCaptureDevice? {
		
		var device : AVCaptureDevice?;
		
		// facingMode ConstrainDOMString NSDictionary
		// Check the video contraints: examine facingMode and deviceId
		// and pick a default if neither are specified.
		var position = AVCaptureDevice.Position.front;
		let facingMode = self.getConstrainDOMStringValue(constraint: "facingMode");
		let facingModeRequired = self.isConstrainDOMStringRequired(constraint: "facingMode");
		if (facingMode.count > 0) {
			if (facingMode == "environment") {
				position = AVCaptureDevice.Position.back
			} else if (facingMode == "user") {
				position = AVCaptureDevice.Position.front
			} else if (facingModeRequired) {
				// TODO fail
				return nil;
			}
			
			NSLog("PluginRTCVideoCaptureController#findDevice facingMode:%s", facingMode);
		}
		
		// deviceId ConstrainDOMString NSDictionary
		let deviceId = self.getConstrainDOMStringValue(constraint: "deviceId");
		if (deviceId.count > 0) {
			device = AVCaptureDevice(uniqueID: deviceId)
			if (!device!.isConnected) {
				device = nil
			}
			
			if (device == nil && self.isConstrainDOMStringRequired(constraint: "deviceId")) {
				// TODO fail
				return nil;
			}
		}

		if (device == nil) {
			device = findDeviceForPosition(position: position);
		}
		
		NSLog("PluginRTCVideoCaptureController#findDevice device:%@", device!);
		
		// Check facingMode requirements
		if (facingModeRequired && (
			device == nil ||
				facingMode == "environment" && device?.position != AVCaptureDevice.Position.back ||
					facingMode == "user" && device?.position != AVCaptureDevice.Position.front
		)) {
		   // TODO fail
		   return nil;
		}
		
		deviceFormat = findFormatForDevice(device:device!);
		
		if (deviceFormat == nil) {
			return nil;
		}
		
		let frameRateRange: NSDictionary = getConstrainRangeValues(constraint: "frameRate", defaultValue: self.DEFAULT_FPS),
			minFrameRate = frameRateRange.object(forKey: "min") as! Float64,
			maxFrameRate = frameRateRange.object(forKey: "max") as! Float64
			
		if (minFrameRate > 0 || maxFrameRate > 0) {
			let formatFrameRateRange: AVFrameRateRange = deviceFormat!.videoSupportedFrameRateRanges[0]
		 
			if (
				(formatFrameRateRange.maxFrameRate <= maxFrameRate) &&
					formatFrameRateRange.minFrameRate >= minFrameRate &&
						isConstrainRangeRequired(constraint: "frameRate")
			) {
				// TODO fail
				return nil;
			}
			
			deviceFrameRate = Int(maxFrameRate > 0 ? maxFrameRate : minFrameRate)
			
			NSLog("PluginRTCVideoCaptureController#findDevice deviceFrameRate:%i", deviceFrameRate!);
			
		// Apply default deviceFrameRate
		} else {
			deviceFrameRate = DEFAULT_FPS;
		}
		
		return device;
	}
	
	fileprivate func findDeviceForPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
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
	
	
	
	fileprivate func findFormatForDevice(device: AVCaptureDevice) -> AVCaptureDevice.Format? {
		
		var selectedFormat: AVCaptureDevice.Format? = nil
		let formats: NSArray = RTCCameraVideoCapturer.supportedFormats(for: device) as NSArray
		
		let widthRange: NSDictionary = getConstrainRangeValues(constraint: "width", defaultValue: self.DEFAULT_WIDTH),
			minWidth = widthRange.object(forKey: "min") as! Int32,
			maxWidth = widthRange.object(forKey: "max") as! Int32
			
		let heightRange: NSDictionary = getConstrainRangeValues(constraint: "height", defaultValue: self.DEFAULT_HEIGHT),
			minHeight = heightRange.object(forKey: "min") as! Int32,
			maxHeight = heightRange.object(forKey: "max") as! Int32
		
		let frameRateRange: NSDictionary = getConstrainRangeValues(constraint: "frameRate", defaultValue: self.DEFAULT_FPS),
			minFrameRate = frameRateRange.object(forKey: "min") as! Float64,
			maxFrameRate = frameRateRange.object(forKey: "max") as! Float64

		let aspectRatioRange: NSDictionary = getConstrainRangeValues(constraint: "aspectRatio"),
			minAspectRatio = aspectRatioRange.object(forKey: "min") as! Float32,
			maxAspectRatio = aspectRatioRange.object(forKey: "max") as! Float32
		

		NSLog("PluginRTCVideoCaptureController#findFormatForDevice contraints width:%i/%i, height:%i/%i, aspectRatio: %f/%f, frameRateRanges:%f/%f", minWidth, maxWidth, minHeight, maxHeight, minAspectRatio, maxAspectRatio, minFrameRate, maxFrameRate);
		
		for format: Any in formats {
			
			let devFormat: AVCaptureDevice.Format = format as! AVCaptureDevice.Format
			let pixelFormat: FourCharCode = CMFormatDescriptionGetMediaSubType(devFormat.formatDescription)
		
			let dimension: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(devFormat.formatDescription)
			
			let aspectRatio : Float32 = (Float32(dimension.width) / Float32(dimension.height));
			
			let frameRateRanges: [AVFrameRateRange] = devFormat.videoSupportedFrameRateRanges
			let frameRates = frameRateRanges[0];
			
			NSLog("PluginRTCVideoCaptureController#findFormatForDevice format width:%i, height:%i, aspectRatio: %f, frameRateRanges:%f/%f", dimension.width, dimension.height, aspectRatio, frameRates.minFrameRate, frameRates.maxFrameRate);
			
			// dimension.height and dimension.width Matches
			if (
				((maxHeight == 0 || dimension.height <= maxHeight) && (minHeight == 0 || dimension.height >= minHeight)) &&
						((maxWidth == 0 || dimension.width <= maxWidth) && (minWidth == 0 || dimension.width >= minWidth))
			) {
				//NSLog("dimension %i/%i",  dimension.width,  dimension.height);
				selectedFormat = devFormat
			} else {
				
				// Skip next tests
			   continue
			}
			
			if (
				(minAspectRatio == 0 && maxAspectRatio == 0) || (
					(minAspectRatio == 0 || aspectRatio == minAspectRatio) &&
						(maxAspectRatio == 0 || aspectRatio == maxAspectRatio)
				)
			) {
				selectedFormat = devFormat
			} else {
				
				if (selectedFormat == devFormat) {
					selectedFormat = nil;
				}
					
				// Skip next tests
				continue
			}
			
			if (
				(minFrameRate == 0 && maxFrameRate == 0) || (
					(maxFrameRate == 0 || frameRates.maxFrameRate >= maxFrameRate) &&
						(minFrameRate  == 0 || frameRates.minFrameRate <= minFrameRate)
					)
			) {
				selectedFormat = devFormat
			} else {
				if (selectedFormat == devFormat) {
					selectedFormat = nil;
				}
				
				// Skip next tests
				continue
			}
				
			if (pixelFormat == self.capturer.preferredOutputPixelFormat()) {
				selectedFormat = devFormat
			}
		}

		if (selectedFormat != nil) {

			let dimension: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(selectedFormat!.formatDescription)
			let aspectRatio : Float32 = (Float32(dimension.width) / Float32(dimension.height));
			let frameRateRanges: [AVFrameRateRange] = selectedFormat!.videoSupportedFrameRateRanges
			let frameRates = frameRateRanges[0];
			
			// TODO Apply frameRates via minFrameRate/maxFrameRate
			
			NSLog("PluginRTCVideoCaptureController#findFormatForDevice width:%i, height:%i, aspectRatio: %f, frameRateRanges:%f/%f", dimension.width, dimension.height, aspectRatio, frameRates.minFrameRate, frameRates.maxFrameRate);
		}
	
		return selectedFormat
	}
	
	func switchCamera() -> Bool {
		
		if (self.capturer.captureSession.isRunning) {
			self.capturer.stopCapture()
		}

		self.device = self.findAlternativeDevicePosition(currentDevice: self.device)
		
		self.deviceFormat = self.findFormatForDevice(device: self.device!)
		
		return self.startCapture()
	}
	
	fileprivate func findAlternativeDevicePosition(currentDevice: AVCaptureDevice?) -> AVCaptureDevice? {
		let captureDevices: NSArray = RTCCameraVideoCapturer.captureDevices() as NSArray
		for device: Any in captureDevices {
			let avDevice = device as! AVCaptureDevice
			if (avDevice.position != currentDevice!.position) {
				return avDevice
			}
		}
	
		return nil
	}
	
	//
	//
	//
	
	fileprivate func getConstrainDOMStringValue(constraint: String) -> String {
		var finalValue: String = "";
		let constraints = self.constraints;
		let value = constraints.object(forKey: constraint);
		
		if value is String {
			finalValue = value as! String
		} else if value is NSDictionary {
			let value = value as! NSDictionary;
			if (value.object(forKey: "exact") != nil) {
				finalValue = value.object(forKey: "exact") as! String
			} else if (value.object(forKey: "ideal") != nil) {
				finalValue = value.object(forKey: "ideal") as! String
			}
		}
		
		return finalValue;
	}
	
	fileprivate func isConstrainDOMStringRequired(constraint: String) -> Bool {
		var isRequired: Bool = false;
		let constraints = self.constraints;
		let value = constraints.object(forKey: constraint);
		
		if value is String {
			isRequired = (value as! String).count > 0;
		} else if value is NSDictionary {
			let value = value as! NSDictionary;
			if (value.object(forKey: "exact") != nil) {
				isRequired = (value.object(forKey: "exact") as! String).count > 0
			} else if (value.object(forKey: "ideal") != nil) {
				isRequired = false;
			}
		}
		
		return isRequired;
	}
	
	fileprivate func getConstrainRangeValues(constraint: String, defaultValue: Int = 0) -> NSDictionary {
		let constraints = self.constraints;
		let finalValue: NSMutableDictionary = [:];
		finalValue.setValue(defaultValue, forKey: "min")
		finalValue.setValue(defaultValue, forKey: "max")
		
		let value = constraints.object(forKey: constraint);
		
		if value is Int64 {
			finalValue.setValue(value, forKey: "min")
			finalValue.setValue(value, forKey: "max")
		} else if value is NSDictionary {
			let value = value as! NSDictionary;
			if (value.object(forKey: "exact") != nil) {
				let value = value.object(forKey: "exact") as! Int64
				finalValue.setValue(value, forKey: "min")
				finalValue.setValue(value, forKey: "max")
			} else if (value.object(forKey: "ideal") != nil) {
				let value = value.object(forKey: "ideal") as! Int64
				finalValue.setValue(value, forKey: "min")
				finalValue.setValue(value, forKey: "max")
			} else {
				if (value.object(forKey: "min") != nil) {
					let value = value.object(forKey: "min") as! Int64
					finalValue.setValue(value, forKey: "min")
				}
				if (value.object(forKey: "max") != nil) {
					let value = value.object(forKey: "max") as! Int64
					finalValue.setValue(value, forKey: "max")
				}
			}
		}
		
		return finalValue;
	}
	
	fileprivate func isConstrainRangeRequired(constraint: String) -> Bool {
		let constraints = self.constraints;
		var isRequired: Bool = false;
		let value = constraints.object(forKey: constraint);
		
		if value is Int32 {
			isRequired = (value as! Int32) > 0;
		} else if value is NSDictionary {
			if (constraints.object(forKey: "exact") != nil) {
				isRequired = true;
			} else if (constraints.object(forKey: "ideal") != nil) {
				isRequired = false;
			}
		}
		
		return isRequired;
	}
}
