import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var backgroundChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let clipboardChannel = FlutterMethodChannel(name: "app.clipboard", binaryMessenger: controller.binaryMessenger)
      clipboardChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getClipboardImages" {
          var paths: [String] = []
          if let image = UIPasteboard.general.image {
            if let data = image.pngData() ?? image.jpegData(compressionQuality: 0.95) {
              let tmp = NSTemporaryDirectory()
              let filename = "pasted_\(Int(Date().timeIntervalSince1970 * 1000)).png"
              let url = URL(fileURLWithPath: tmp).appendingPathComponent(filename)
              do {
                try data.write(to: url)
                paths.append(url.path)
              } catch {
                // ignore write error
              }
            }
          }
          result(paths)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      
      backgroundChannel = FlutterMethodChannel(name: "app.background", binaryMessenger: controller.binaryMessenger)
      backgroundChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else {
          result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate unavailable", details: nil))
          return
        }
        
        switch call.method {
        case "initialize":
          result(true)
        case "hasPermissions":
          result(true)
        case "enableBackgroundExecution":
          self.beginBackgroundTask()
          result(self.backgroundTaskId != .invalid)
        case "disableBackgroundExecution":
          self.endBackgroundTask()
          result(nil)
        case "isBackgroundExecutionEnabled":
          result(self.backgroundTaskId != .invalid)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func beginBackgroundTask() {
    guard backgroundTaskId == .invalid else { return }
    
    backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
    }
  }
  
  private func endBackgroundTask() {
    guard backgroundTaskId != .invalid else { return }
    
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
    backgroundTaskId = .invalid
  }
}
