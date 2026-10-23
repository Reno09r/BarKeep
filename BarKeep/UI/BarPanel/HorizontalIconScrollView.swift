import AppKit
import SwiftUI

/// Горизонтальный скролл для ряда иконок.
///
/// SwiftUI `ScrollView(.horizontal)` не реагирует на обычное вертикальное
/// колесо мыши, поэтому прокрутку обрабатываем в `NSScrollView` вручную.
struct HorizontalIconScrollView<Content: View>: NSViewRepresentable {
    /// Ширина контента. `NSHostingView.fittingSize` для SwiftUI-ряда равен нулю,
    /// поэтому ширину документа задаём явно.
    let contentWidth: CGFloat
    private let content: Content

    init(contentWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.contentWidth = contentWidth
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WheelScrollView {
        let scroll = WheelScrollView()
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.horizontalScrollElasticity = .automatic
        scroll.verticalScrollElasticity = .none
        scroll.autohidesScrollers = true

        let document = FlippedDocumentView(frame: NSRect(x: 0, y: 0, width: 1, height: 44))
        let hosting = NSHostingView(rootView: content)
        hosting.sizingOptions = []
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.frame = document.bounds
        hosting.autoresizingMask = [.width, .height]
        document.addSubview(hosting)
        scroll.documentView = document

        context.coordinator.contentWidth = contentWidth
        scroll.onLayout = { [weak scroll, weak coordinator = context.coordinator] in
            guard let scroll else { return }
            coordinator?.layoutDocument(in: scroll)
        }
        context.coordinator.layoutDocument(in: scroll)
        return scroll
    }

    func updateNSView(_ scroll: WheelScrollView, context: Context) {
        if let document = scroll.documentView as? FlippedDocumentView,
           let hosting = document.subviews.first as? NSHostingView<Content> {
            hosting.rootView = content
        }
        context.coordinator.contentWidth = contentWidth
        context.coordinator.layoutDocument(in: scroll)
    }

    final class Coordinator {
        var contentWidth: CGFloat = 1

        func layoutDocument(in scroll: WheelScrollView) {
            guard let document = scroll.documentView as? FlippedDocumentView else { return }
            let clip = scroll.contentSize
            let height = clip.height > 0 ? clip.height : 44
            let width = max(contentWidth, clip.width, 1)

            if abs(document.frame.width - width) > 0.5 || abs(document.frame.height - height) > 0.5 {
                document.frame = NSRect(x: 0, y: 0, width: width, height: height)
            }

            // После фильтрации поиском контент может стать короче — поджимаем скролл.
            let maxX = max(0, width - clip.width)
            if scroll.contentView.bounds.origin.x > maxX {
                scroll.contentView.scroll(to: NSPoint(x: maxX, y: 0))
                scroll.reflectScrolledClipView(scroll.contentView)
            }
        }
    }
}

/// Документ скролла с верхним левым началом координат, чтобы контент
/// не уезжал вверх и не обрезался панелью.
final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}

final class WheelScrollView: NSScrollView {
    var onLayout: (() -> Void)?

    override func layout() {
        super.layout()
        onLayout?()
    }

    override func scrollWheel(with event: NSEvent) {
        let clip = contentView
        let maxX = max(0, (documentView?.frame.width ?? 0) - clip.bounds.width)
        guard maxX > 0 else { return }

        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        var delta: CGFloat

        if abs(dx) > abs(dy) {
            delta = dx
        } else {
            // Вертикальное колесо/свайп двигает ряд по горизонтали.
            delta = dy
        }
        if !event.hasPreciseScrollingDeltas {
            delta *= 10
        }
        guard abs(delta) > 0.01 else { return }

        var origin = clip.bounds.origin
        origin.x = min(max(0, origin.x - delta), maxX)
        clip.scroll(to: origin)
        reflectScrolledClipView(clip)
    }
}
