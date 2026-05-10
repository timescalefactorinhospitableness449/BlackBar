import AppKit
import SwiftUI

@MainActor
protocol MenuItemMeasuring: AnyObject {
    func measuredHeight(width: CGFloat) -> CGFloat
}

@MainActor
final class MenuItemHostingView: NSView, MenuItemMeasuring {
    private enum Metrics {
        static let proposedHeight: CGFloat = 720
        static let maxHeight: CGFloat = 280
        static let fallbackHeight: CGFloat = 28
    }

    private let hostingController: NSHostingController<AnyView>
    private var cachedWidth: CGFloat?
    private var cachedHeight: CGFloat?

    override var allowsVibrancy: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        let size = self.hostingController.view.intrinsicContentSize
        guard self.bounds.width > 0 else { return size }
        return NSSize(width: self.bounds.width, height: size.height)
    }

    init(rootView: AnyView) {
        self.hostingController = NSHostingController(rootView: rootView)
        super.init(frame: .zero)
        self.configureHostingView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        self.hostingController.view.frame = self.bounds
    }

    func measuredHeight(width: CGFloat) -> CGFloat {
        if self.cachedWidth == width, let cachedHeight {
            return cachedHeight
        }
        if self.frame.size.width != width || self.bounds.size.width != width {
            self.frame.size.width = width
            self.bounds.size.width = width
            self.hostingController.view.frame = self.bounds
            self.invalidateIntrinsicContentSize()
        }

        let proposed = NSSize(width: width, height: Metrics.proposedHeight)
        let measured = self.hostingController.sizeThatFits(in: proposed)
        let height = self.safeMeasuredHeight(from: measured.height)
        let scale = self.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        let rounded = ceil(height * scale) / scale
        self.cachedWidth = width
        self.cachedHeight = rounded
        return rounded
    }

    private func configureHostingView() {
        self.hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        self.hostingController.view.autoresizingMask = [.width, .height]
        self.hostingController.view.frame = self.bounds
        self.addSubview(self.hostingController.view)
        if #available(macOS 13.0, *) {
            self.hostingController.sizingOptions = [.minSize, .intrinsicContentSize]
        }
    }

    private func safeMeasuredHeight(from height: CGFloat) -> CGFloat {
        if height.isFinite, height > 0 {
            return min(height, Metrics.maxHeight)
        }

        let intrinsic = self.hostingController.view.intrinsicContentSize.height
        if intrinsic.isFinite, intrinsic > 0 {
            return min(intrinsic, Metrics.maxHeight)
        }

        return Metrics.fallbackHeight
    }
}
