
import FacebookCore
import FacebookLogin
import FacebookShare
import Flutter
import TwitterKit
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let twitterShareChannel = FlutterMethodChannel(
      name: "twitter_share", binaryMessenger: controller.binaryMessenger)
    twitterShareChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "shareToTwitter" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        let url = arguments["url"] as? String
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "The arguments are invalid", details: nil))
        return
      }

      let composer = TWTRComposer()
      composer.setText(text)
      composer.setURL(URL(string: url))

      composer.show(from: controller) { result in
        switch result {
        case .done:
          print("se hizo")
        // result("SUCCESS")
        default:
          print("no se hizo")
        // result(FlutterError(code: "SHARE_FAILED", message: "The sharing process failed", details: nil))
        }
      }
      result("hola")
    })

    let facebookShareChannel = FlutterMethodChannel(
      name: "facebook_share", binaryMessenger: controller.binaryMessenger)

    facebookShareChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "shareToFacebook" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let args = call.arguments as? [String: Any],
        let text = args["text"] as? String,
        let urlString = args["url"] as? String,
        let url = URL(string: urlString)
      {

        self?.shareToFacebook(text: text, url: url)
        result("Shared to Facebook")
      } else {
        result(FlutterError(code: "Invalid Arguments", message: nil, details: nil))
      }
    })

    let facebookLoginChannel = FlutterMethodChannel(
      name: "facebook_auth", binaryMessenger: controller.binaryMessenger)

    facebookLoginChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "loginToFacebook" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let loginManager = LoginManager()
      loginManager.logIn(
        permissions: [.publicProfile, .email],
        viewController: UIApplication.shared.windows.first?.rootViewController
      ) { loginResult in
        switch loginResult {
        case .cancelled:
          result(FlutterError(code: "Login Cancelled", message: nil, details: nil))
        case .failed(let error):
          result(
            FlutterError(code: "Login Failed", message: error.localizedDescription, details: nil))
        case .success(let grantedPermissions, _, let accessToken):
          let response: [String: Any] = [
            "token": accessToken.tokenString
          ]
          result(response)
        }
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func shareToFacebook(text: String, url: URL) {
    let shareContent = ShareLinkContent()
    shareContent.contentURL = url
    shareContent.quote = text
    let dialog = ShareDialog(
      fromViewController: UIApplication.shared.windows.first?.rootViewController,
      content: shareContent, delegate: nil)
    dialog.show()
  }
}