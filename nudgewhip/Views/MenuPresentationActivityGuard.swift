import SwiftUI

/// MenuBarExtra content is rendered in a tracking context, not a normal app window.
/// While this view is visible, hover/mouse movement inside depth menus must not be
/// treated as observed activity, otherwise the menu can invalidate and flicker.
struct MenuPresentationActivityGuard: ViewModifier {
    let menuBarViewModel: MenuBarViewModel
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                menuBarViewModel.setMenuPresentationActive(true)
            }
            .onDisappear {
                menuBarViewModel.setMenuPresentationActive(false)
            }
    }
}

extension View {
    func trackMenuPresentation(using menuBarViewModel: MenuBarViewModel) -> some View {
        modifier(MenuPresentationActivityGuard(menuBarViewModel: menuBarViewModel))
    }
}
