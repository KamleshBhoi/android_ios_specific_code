
import UIKit
import Flutter
import CropViewController

@main
@objc class AppDelegate: FlutterAppDelegate,
                         CropViewControllerDelegate {

    private let CHANNEL = "com.example.image_editor/crop"

    private var pendingCropResult: FlutterResult?

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
                [weak self] call, result in

                guard let self = self else { return }

                switch call.method {

                case "cropImage":
                    self.startNativeCrop(
                        call: call,
                        result: result
                    )

                case "flipImage":
                    self.flipImage(
                        call: call,
                        result: result
                    )

                case "rotateImage":
                    self.rotateImage(
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

    // MARK: - Native Interactive Cropping

    private func startNativeCrop(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        guard pendingCropResult == nil else {
            result(
                FlutterError(
                    code: "BUSY",
                    message: "Another crop operation is running",
                    details: nil
                )
            )
            return
        }

        guard
            let arguments = call.arguments as? [String: Any],
            let imageData = arguments["imageBytes"] as? FlutterStandardTypedData,
            let image = UIImage(data: imageData.data)
        else {
            result(
                FlutterError(
                    code: "INVALID_IMAGE",
                    message: "Unable to load image",
                    details: nil
                )
            )
            return
        }

        guard let controller =
            window?.rootViewController as? FlutterViewController else {
            result(
                FlutterError(
                    code: "NO_CONTROLLER",
                    message: "Flutter controller not found",
                    details: nil
                )
            )
            return
        }

        let cropController = CropViewController(
            image: image
        )

        cropController.delegate = self

        pendingCropResult = result

        controller.present(
            cropController,
            animated: true
        )
    }

    // MARK: - Crop Success

    func cropViewController(
        _ cropViewController: CropViewController,
        didCropToImage image: UIImage,
        withRect cropRect: CGRect,
        angle: Int
    ) {

        let output = image.jpegData(
            compressionQuality: 0.95
        )

        let callback = pendingCropResult
        pendingCropResult = nil

        cropViewController.dismiss(
            animated: true
        ) {
            if let output = output {
                callback?(
                    FlutterStandardTypedData(bytes: output)
                )
            } else {
                callback?(
                    FlutterError(
                        code: "ENCODE_ERROR",
                        message: "Unable to encode cropped image",
                        details: nil
                    )
                )
            }
        }
    }

    // MARK: - Crop Cancel

    func cropViewController(
        _ cropViewController: CropViewController,
        didFinishCancelled cancelled: Bool
    ) {

        let callback = pendingCropResult
        pendingCropResult = nil

        cropViewController.dismiss(
            animated: true
        ) {
            callback?(nil)
        }
    }

    // MARK: - Native Flip

    private func flipImage(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        guard
            let arguments = call.arguments as? [String: Any],
            let imageData = arguments["imageBytes"] as? FlutterStandardTypedData,
            let image = UIImage(data: imageData.data)
        else {
            result(
                FlutterError(
                    code: "INVALID_IMAGE",
                    message: "Unable to load image",
                    details: nil
                )
            )
            return
        }

        let horizontal =
            arguments["horizontal"] as? Bool ?? true

        let normalized = normalize(image)

        let size = normalized.size

        let renderer = UIGraphicsImageRenderer(size: size)

        let flipped = renderer.image { context in

            if horizontal {
                context.cgContext.translateBy(
                    x: size.width,
                    y: 0
                )

                context.cgContext.scaleBy(
                    x: -1,
                    y: 1
                )
            } else {
                context.cgContext.translateBy(
                    x: 0,
                    y: size.height
                )

                context.cgContext.scaleBy(
                    x: 1,
                    y: -1
                )
            }

            normalized.draw(
                in: CGRect(origin: .zero, size: size)
            )
        }

        returnImage(flipped, result: result)
    }

    // MARK: - Native Rotation

    private func rotateImage(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        guard
            let arguments = call.arguments as? [String: Any],
            let imageData = arguments["imageBytes"] as? FlutterStandardTypedData,
            let image = UIImage(data: imageData.data)
        else {
            result(
                FlutterError(
                    code: "INVALID_IMAGE",
                    message: "Unable to load image",
                    details: nil
                )
            )
            return
        }

        let normalized = normalize(image)

        let oldSize = normalized.size

        let newSize = CGSize(
            width: oldSize.height,
            height: oldSize.width
        )

        let renderer = UIGraphicsImageRenderer(
            size: newSize
        )

        let rotated = renderer.image { context in

            context.cgContext.translateBy(
                x: newSize.width / 2,
                y: newSize.height / 2
            )

            context.cgContext.rotate(
                by: .pi / 2
            )

            normalized.draw(
                in: CGRect(
                    x: -oldSize.width / 2,
                    y: -oldSize.height / 2,
                    width: oldSize.width,
                    height: oldSize.height
                )
            )
        }

        returnImage(rotated, result: result)
    }

    // MARK: - Normalize Image Orientation

    private func normalize(_ image: UIImage) -> UIImage {

        let renderer = UIGraphicsImageRenderer(
            size: image.size
        )

        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: image.size
                )
            )
        }
    }

    // MARK: - Return Image Bytes

    private func returnImage(
        _ image: UIImage,
        result: @escaping FlutterResult
    ) {

        guard let data = image.jpegData(
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
            FlutterStandardTypedData(bytes: data)
        )
    }
}
