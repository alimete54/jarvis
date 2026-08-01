import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let torchChannel = FlutterMethodChannel(
      name: "jarvis/torch",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    torchChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "setTorch" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let on = args["on"] as? Bool,
            let device = AVCaptureDevice.default(for: .video),
            device.hasTorch else {
        result(FlutterError(
          code: "TORCH_UNAVAILABLE",
          message: "Bu cihazda el feneri yok veya kamera izni verilmedi",
          details: nil))
        return
      }
      do {
        try device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
        result(true)
      } catch {
        result(FlutterError(code: "TORCH_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }
}
