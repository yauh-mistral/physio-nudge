import AppKit
import ImageIO

/// Spielt animierte GIFs frame-weise ab (NSImageView animiert GIFs nicht
/// von selbst; Details: requirements/08-technische-architektur.md).
final class GifAnimator {
    private struct Frame {
        let image: NSImage
        let duration: Double
    }

    private let frames: [Frame]
    private(set) var loopDuration: Double
    private var timer: Timer?
    private var index = 0
    private weak var imageView: NSImageView?

    init?(url: URL) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var loaded: [Frame] = []
        var total = 0.0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }

            var duration = 0.1
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                let delay = gif[kCGImagePropertyGIFUnclampedDelayTime]
                    ?? gif[kCGImagePropertyGIFDelayTime]
                if let value = delay as? Double, value > 0 {
                    duration = value
                }
            }

            let image = NSImage(cgImage: cgImage,
                                size: NSSize(width: cgImage.width, height: cgImage.height))
            loaded.append(Frame(image: image, duration: duration))
            total += duration
        }

        guard !loaded.isEmpty else { return nil }
        frames = loaded
        loopDuration = total
    }

    func start(in imageView: NSImageView) {
        stop()
        self.imageView = imageView
        index = 0
        imageView.image = frames[0].image
        scheduleNextFrame()
    }

    private func scheduleNextFrame() {
        index = (index + 1) % frames.count
        let frame = frames[index]
        imageView?.image = frame.image
        timer = Timer.scheduledTimer(withTimeInterval: frame.duration, repeats: false) { [weak self] _ in
            self?.scheduleNextFrame()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        imageView = nil
    }
}
