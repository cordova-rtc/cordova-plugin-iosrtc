import Foundation


class PluginUtils {
	class func randomInt(_ min: Int, max: Int) -> Int {
		return Int(arc4random_uniform(UInt32(max - min))) + min
	}
}
