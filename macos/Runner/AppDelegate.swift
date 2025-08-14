import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {

      let channel = FlutterMethodChannel(name: "com.gemtalk.gemstone",
                                         binaryMessenger: controller.engine.binaryMessenger)

      channel.setMethodCallHandler { call, result in
        if call.method == "getExecutablePath" {
          if let toolsPath = Bundle.main.resourcePath?.appending("/product") {
            result(toolsPath)
          } else {
            result(FlutterError(code: "NOT_FOUND", message: "Executable not found", details: nil))
          }
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
