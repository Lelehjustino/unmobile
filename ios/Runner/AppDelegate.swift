import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let mobileIdChannel = FlutterMethodChannel(name: "com.un.mobile/mobile_id",
                                              binaryMessenger: controller.binaryMessenger)
    mobileIdChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getNativeId" {
          if let uuid = UIDevice.current.identifierForVendor?.uuidString {
              result(uuid)
          } else {
              result(FlutterError(code: "UNAVAILABLE",
                                message: "Identifier for vendor not available.",
                                details: nil))
          }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
