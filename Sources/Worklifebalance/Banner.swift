import SwiftUI

private let bannerSize = NSSize(width: 344, height: 72)
private let screenMargin: CGFloat = 12
/// Seconds before the banner hides itself (paused while hovered)
private let displayDuration: TimeInterval = 8

private class BannerModel: ObservableObject {
    @Published var title = ""
    @Published var body = ""
    @Published var hovered = false
    var startNext: (() -> Void)?
}

private class BannerPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for _: NSEvent?) -> Bool { true }
}

/// Tracks hover even while the app is in the background
private class HoverTrackingView: NSView {
    var onHover: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    override func mouseEntered(with _: NSEvent) { onHover?(true) }
    override func mouseExited(with _: NSEvent) { onHover?(false) }
}

private struct BannerView: View {
    @ObservedObject var model: BannerModel
    @ObservedObject private var l10n = L10n.shared
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(model.body)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let startNext = model.startNext {
                    Button(l10n.t("notify.startNext")) {
                        startNext()
                        dismiss()
                    }
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: dismiss)

            if model.hovered {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color(nsColor: .windowBackgroundColor)))
                        .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help(l10n.t("notify.dismiss"))
                .padding(5)
            }
        }
        .frame(width: bannerSize.width, height: bannerSize.height)
    }
}

/// A small floating reminder styled after macOS notification banners
class TBBanner {
    static let shared = TBBanner()

    private let model = BannerModel()
    private var panel: BannerPanel?
    private var hideWorkItem: DispatchWorkItem?

    func show(title: String, body: String, startNext: (() -> Void)?) {
        model.title = title
        model.body = body
        model.startNext = startNext
        model.hovered = false

        let panel = self.panel ?? makePanel()
        self.panel = panel
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let target = NSRect(x: visible.maxX - bannerSize.width - screenMargin,
                            y: visible.maxY - bannerSize.height - screenMargin,
                            width: bannerSize.width, height: bannerSize.height)

        if !panel.isVisible {
            // Slide in from beyond the right edge of the screen
            panel.setFrame(target.offsetBy(dx: bannerSize.width + screenMargin * 2, dy: 0),
                           display: false)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.45
            // Slight overshoot, like the system's spring-in banners
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.1, 0.35, 1)
            panel.animator().setFrame(target, display: true)
        }
        scheduleHide(after: displayDuration)
    }

    func hide() {
        hideWorkItem?.cancel()
        guard let panel = panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(panel.frame.offsetBy(dx: bannerSize.width / 2, dy: 0),
                                      display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    private func scheduleHide(after delay: TimeInterval) {
        hideWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.model.hovered {
                self.scheduleHide(after: 2)
            } else {
                self.hide()
            }
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func makePanel() -> BannerPanel {
        let panel = BannerPanel(contentRect: NSRect(origin: .zero, size: bannerSize),
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let frame = NSRect(origin: .zero, size: bannerSize)
        let hover = HoverTrackingView(frame: frame)
        hover.autoresizingMask = [.width, .height]
        hover.onHover = { [weak self] over in self?.model.hovered = over }

        let host = ClickThroughHostingView(rootView: BannerView(model: model) { [weak self] in
            self?.hide()
        })
        host.frame = frame
        host.autoresizingMask = [.width, .height]
        hover.addSubview(host)

        // Frosted like system notifications; clear glass would hurt legibility here
        let effect = NSVisualEffectView(frame: frame)
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        if #available(macOS 26, *) {
            effect.layer?.cornerRadius = 22
            effect.layer?.cornerCurve = .continuous
        } else {
            effect.layer?.cornerRadius = 16
        }
        effect.layer?.masksToBounds = true
        effect.addSubview(hover)
        panel.contentView = effect
        return panel
    }
}
