// ContentView.swift
// 메뉴바 드롭다운의 최상위 뷰.
//
// 메뉴바 드롭다운의 렌더링 전용 엔트리.
// 데이터는 MenuBarViewModel이 미리 계산한 스냅샷을 사용한다.

import SwiftUI

struct ContentView: View {
    let menuBarViewModel: MenuBarViewModel
    let onOpenSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let onQuit: () -> Void

    var body: some View {
        MenuBarDropdownView(
            menuBarViewModel: menuBarViewModel,
            onOpenSettings: onOpenSettings,
            onOpenOnboarding: onOpenOnboarding,
            onQuit: onQuit
        )
        .padding(16)
        .frame(width: 320)
        .trackMenuPresentation(using: menuBarViewModel)
    }
}

#Preview {
    ContentView(
        menuBarViewModel: MenuBarViewModel(),
        onOpenSettings: {},
        onOpenOnboarding: {},
        onQuit: {}
    )
}
