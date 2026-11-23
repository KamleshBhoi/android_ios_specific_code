import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let CHANNEL = "com.example.image_editor/crop"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        let result = super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        if let controller =
            window?.rootViewController as? FlutterViewController {

            let channel = FlutterMethodChannel(
                name: CHANNEL,
                binaryMessenger: controller.binaryMessenger
            )

            channel.setMethodCallHandler {
                call, result in

                switch call.method {

                case "cropImage":
                    self.cropImage(
                        call: call,
                        result: result
                    )

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return result
    }

    // Native iOS image cropping
    private func cropImage(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        guard
            let arguments = call.arguments as? [String: Any],
            let imageData = arguments["imageBytes"] as? FlutterStandardTypedData,
            let image = UIImage(data: imageData.data),
            let cgImage = image.cgImage
        else {
            result(
                FlutterError(
                    code: "INVALID_IMAGE",
                    message: "Unable to read image",
                    details: nil
                )
            )
            return
        }

        let width = cgImage.width
        let height = cgImage.height

        // Native center-square cropping
        let cropSize = min(width, height)

        let x = (width - cropSize) / 2
        let y = (height - cropSize) / 2

        let cropRect = CGRect(
            x: x,
            y: y,
            width: cropSize,
            height: cropSize
        )

        guard let croppedCGImage = cgImage.cropping(
            to: cropRect
        ) else {
            result(
                FlutterError(
                    code: "CROP_ERROR",
                    message: "Unable to crop image",
                    details: nil
                )
            )
            return
        }

        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: image.scale,
            orientation: .up
        )

        guard let outputData = croppedImage.jpegData(
            compressionQuality: 0.95
        ) else {
            result(
                FlutterError(
                    code: "ENCODE_ERROR",
                    message: "Unable to encode image",
                    details: nil
                )
            )
            return
        }

        result(
            FlutterStandardTypedData(bytes: outputData)
        )
    }
}
