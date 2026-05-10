import AppKit

enum StatusBarImage {
    static func render(snapshot: DashboardSnapshot, history: [Int]) -> NSImage {
        let text = "\(snapshot.usage.activeVCPU)"
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let textSize = text.size(withAttributes: textAttributes)
        let textX: CGFloat = 13
        let graphWidth: CGFloat = 54
        let graphSpacing: CGFloat = 5
        let trailingPadding: CGFloat = 4
        let width = ceil(textX + textSize.width + graphSpacing + graphWidth + trailingPadding)
        let size = NSSize(width: width, height: 22)
        let image = NSImage(size: size)
        image.lockFocusFlipped(false)

        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        let color = snapshot.isOperational ? NSColor.systemGreen : NSColor.systemOrange
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 3, y: 8, width: 6, height: 6)).fill()

        text.draw(
            at: NSPoint(x: textX, y: floor((size.height - textSize.height) / 2) + 1),
            withAttributes: textAttributes
        )

        let graphX = ceil(textX + textSize.width + graphSpacing)
        let graphRect = NSRect(x: graphX, y: 3, width: graphWidth, height: 16)
        drawGraph(history: history, in: graphRect, active: snapshot.usage.activeVCPU)

        image.unlockFocus()
        return image
    }

    private static func drawGraph(history: [Int], in rect: NSRect, active: Int) {
        let values = Array(history.suffix(18))
        let maxValue = max(values.max() ?? active, active, 1)
        let barWidth: CGFloat = 2
        let spacing: CGFloat = 1
        let startX = rect.maxX - CGFloat(values.count) * (barWidth + spacing)

        NSColor.separatorColor.withAlphaComponent(0.5).setStroke()
        let baseline = NSBezierPath()
        baseline.move(to: NSPoint(x: rect.minX, y: rect.minY))
        baseline.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        baseline.stroke()

        for (index, value) in values.enumerated() {
            let height = max(CGFloat(2), rect.height * CGFloat(value) / CGFloat(maxValue))
            let x = max(rect.minX, startX + CGFloat(index) * (barWidth + spacing))
            let y = rect.minY
            let barRect = NSRect(x: x, y: y, width: barWidth, height: height)
            let path = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
            (value == 0 ? NSColor.secondaryLabelColor : NSColor.systemCyan).setFill()
            path.fill()
        }
    }
}
