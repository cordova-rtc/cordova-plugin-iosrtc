import Foundation


class PluginUtils {
	class func randomInt(min: Int, max: Int) -> Int {
		return Int(arc4random_uniform(UInt32(max - min))) + min
	}

	// class func randomString(len: Int) -> String {
	// 	let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	// 	var randomString: NSMutableString = NSMutableString(capacity: len)

	// 	for (var i = 0; i < len; i++) {
	// 			var length = UInt32(letters.length)
	// 			var rand = arc4random_uniform(length)
	// 			randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
	// 	}

	// 	return randomString as String
	// }

	// class func delay(delay: Double, closure: () -> ()) {
	// 	dispatch_after(
	// 		dispatch_time(
	// 			DISPATCH_TIME_NOW,
	// 			Int64(delay * Double(NSEC_PER_SEC))
	// 		),
	// 		dispatch_get_main_queue(),
	// 		closure
	// 	)
	// }
}
