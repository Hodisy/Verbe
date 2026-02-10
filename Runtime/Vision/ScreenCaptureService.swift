import AppKit
import ScreenCaptureKit
import CoreGraphics
import AVFoundation

// MARK: - Screen Capture Service (ScreenCaptureKit, macOS 15 only)

@MainActor
final class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    private init() {}

    // MARK: - Public API (async single-frame)

    /// Captures the entire main screen as a single frame.
    func captureFullScreen(maxDimension: CGFloat = 2048) async throws -> NSImage {
        // No explicit authorization call; starting the stream will surface permissions if needed.

        let content = try await SCShareableContent.current
        guard let display = pickMainDisplay(from: content.displays) else {
            throw CaptureError.noScreen
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = false
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA

        let cgImage = try await captureSingleCGImage(filter: filter, configuration: configuration)
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeIfNeeded(nsImage, maxDimension: maxDimension)
    }

    /// Captures the frontmost window (excluding our app) as a single frame.
    func captureFrontmostWindow(maxDimension: CGFloat = 2048) async throws -> NSImage {
        // No explicit authorization call; starting the stream will surface permissions if needed.

        let ourPID = pid_t(ProcessInfo.processInfo.processIdentifier)
        let content = try await SCShareableContent.current

        // SCShareableContent.windows is z-ordered (frontmost first)
        if let window = content.windows.first(where: { $0.owningApplication?.processID != ourPID }) {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = false
            configuration.width = Int(window.frame.width)
            configuration.height = Int(window.frame.height)
            configuration.pixelFormat = kCVPixelFormatType_32BGRA

            let cgImage = try await captureSingleCGImage(filter: filter, configuration: configuration)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            return resizeIfNeeded(nsImage, maxDimension: maxDimension)
        } else {
            // Fallback to screen capture
            return try await captureFullScreen(maxDimension: maxDimension)
        }
    }

    /// Captures a specific region of the main screen.
    func captureRegion(_ rect: CGRect, maxDimension: CGFloat = 2048) async throws -> NSImage {
        // No explicit authorization call; starting the stream will surface permissions if needed.

        let content = try await SCShareableContent.current
        guard let display = pickMainDisplay(from: content.displays) else {
            throw CaptureError.noScreen
        }

        // Use full-screen filter and crop via SCStreamConfiguration sourceRect
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = false
        configuration.width = Int(rect.width)
        configuration.height = Int(rect.height)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.sourceRect = rect // display coordinates

        let cgImage = try await captureSingleCGImage(filter: filter, configuration: configuration)
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeIfNeeded(nsImage, maxDimension: maxDimension)
    }

    // MARK: - Image Conversion

    func imageToBase64(_ image: NSImage, quality: CGFloat = 0.8) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        else {
            print("❌ Failed to convert image to JPEG")
            return nil
        }
        return jpegData.base64EncodedString()
    }

    func imageToData(_ image: NSImage, quality: CGFloat = 0.8) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        else {
            print("❌ Failed to convert image to data")
            return nil
        }
        return jpegData
    }

    // MARK: - Internals

    // No SCAuthorization usage; permission will be handled when starting the stream.
    private func captureSingleCGImage(filter: SCContentFilter, configuration: SCStreamConfiguration) async throws -> CGImage {
        let output = SingleFrameStreamOutput()
        let stream = SCStream(filter: filter, configuration: configuration, delegate: output)

        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: output.queue)
        try await stream.startCapture()
        defer {
            Task {
                try? await stream.stopCapture()
            }
        }

        let cgImage = try await output.nextCGImage()
        try? stream.removeStreamOutput(output, type: .screen)
        return cgImage
    }

    private func resizeIfNeeded(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        if scale >= 1.0 { return image }

        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let resizedImage = NSImage(size: newSize)

        resizedImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()
        return resizedImage
    }

    // Pick the display that contains NSScreen.main, else fall back to first.
    private func pickMainDisplay(from displays: [SCDisplay]) -> SCDisplay? {
        if let nsMain = NSScreen.main {
            let screenFrame = nsMain.frame
            let center = CGPoint(x: screenFrame.midX, y: screenFrame.midY)
            if let match = displays.first(where: { $0.frame.contains(center) }) {
                return match
            }
        }
        return displays.first
    }

    // MARK: - Errors

    enum CaptureError: LocalizedError {
        case permissionDenied
        case noScreen
        case noFrame

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Screen Recording permission denied"
            case .noScreen: return "No display available"
            case .noFrame: return "Failed to capture a frame"
            }
        }
    }
}

// MARK: - Single-frame SCStreamOutput

private final class SingleFrameStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    private let continuationLock = NSLock()
    private var continuation: CheckedContinuation<CGImage, Error>?
    let queue = DispatchQueue(label: "ScreenCaptureService.SingleFrameStreamOutput")

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        resumeOnce(with: .failure(error))
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            let cgImage = try makeCGImage(from: pixelBuffer)
            resumeOnce(with: .success(cgImage))
        } catch {
            resumeOnce(with: .failure(error))
        }
    }

    func nextCGImage() async throws -> CGImage {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
            continuationLock.lock()
            self.continuation = continuation
            continuationLock.unlock()
        }
    }

    private func resumeOnce(with result: Result<CGImage, Error>) {
        continuationLock.lock()
        let cont = continuation
        continuation = nil
        continuationLock.unlock()
        cont?.resume(with: result)
    }

    private func makeCGImage(from pixelBuffer: CVPixelBuffer) throws -> CGImage {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ScreenCaptureService.CaptureError.noFrame
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let alphaInfo = CGImageAlphaInfo.premultipliedFirst
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: alphaInfo.rawValue))

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw ScreenCaptureService.CaptureError.noFrame
        }

        guard let cgImage = context.makeImage() else {
            throw ScreenCaptureService.CaptureError.noFrame
        }

        return cgImage
    }
}
