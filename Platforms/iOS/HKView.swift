#if os(iOS)

import AVFoundation
import UIKit

open class HKView: UIView {
    public static var defaultBackgroundColor: UIColor = .black

    override open class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    override open var layer: AVSampleBufferDisplayLayer {
        super.layer as! AVSampleBufferDisplayLayer
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            layer.videoGravity = videoGravity
        }
    }

    public var videoFormatDescription: CMVideoFormatDescription? {
        currentStream?.mixer.videoIO.formatDescription
    }

    var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if Thread.isMainThread {
                layer.flushAndRemoveImage()
            }
        }
    }
    var position: AVCaptureDevice.Position = .front
    var currentSampleBuffer: CMSampleBuffer?
    private var observer: NSKeyValueObservation?
    private weak var currentStream: NetStream? {
        didSet {
            oldValue?.mixer.videoIO.renderer = nil
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        awakeFromNib()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        attachStream(nil)
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = HKView.defaultBackgroundColor
        layer.backgroundColor = HKView.defaultBackgroundColor.cgColor
    }

    open func attachStream(_ stream: NetStream?) {
        guard let stream: NetStream = stream else {
            currentStream = nil
            return
        }

        stream.mixer.session.beginConfiguration()
        orientation = stream.mixer.videoIO.orientation
        stream.mixer.session.commitConfiguration()

        stream.lockQueue.async {
            stream.mixer.videoIO.renderer = self
            self.currentStream = stream
            stream.mixer.startRunning()
        }
    }
}

extension HKView: NetStreamRenderer {
    // MARK: NetStreamRenderer
    func enqueue(_ sampleBuffer: CMSampleBuffer?) {
        if Thread.isMainThread {
            currentSampleBuffer = sampleBuffer
            if let sampleBuffer = sampleBuffer {
                layer.enqueue(sampleBuffer)
            }
        } else {
            DispatchQueue.main.async {
                self.enqueue(sampleBuffer)
            }
        }
    }
}

#endif
