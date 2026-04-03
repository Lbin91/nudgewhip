import AppKit
import SwiftUI

enum MenuBarStatusImageFactory {
    private static let imageName = "MenuBarIcon"
    private static let canvasSize = NSSize(width: 18, height: 18)
    private static let pausedSymbolName = "pause.circle.fill"
    
    @MainActor
    static func make(isPaused: Bool) -> NSImage {
        guard isPaused else {
            return baseImage()
        }

        if let symbolImage = NSImage(
            systemSymbolName: pausedSymbolName,
            accessibilityDescription: nil
        )?.copy() as? NSImage {
            symbolImage.size = canvasSize
            symbolImage.isTemplate = true
            return symbolImage
        }

        return baseImage()
    }
    
    @MainActor
    private static func baseImage() -> NSImage {
        let image = (NSImage(named: imageName)?.copy() as? NSImage) ?? NSImage(size: canvasSize)
        image.size = canvasSize
        image.isTemplate = true
        return image
    }
}

struct MenuBarExtraLabelView: View {
    @Bindable var menuBarViewModel: MenuBarViewModel
    let accessibilityLabel: String
    
    var body: some View {
        Image(nsImage: MenuBarStatusImageFactory.make(isPaused: menuBarViewModel.isManualPauseActive))
            .renderingMode(.template)
            .accessibilityLabel(accessibilityLabel)
            .id(menuBarViewModel.isManualPauseActive)
    }
}
