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
        .padding(NudgeWhipSpacing.s3)
        .frame(width: NudgeWhipLayout.popoverWidth)
        .background(popoverSurface)
        .clipShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.popover, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.popover, style: .continuous)
                .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, y: 6)
        .trackMenuPresentation(using: menuBarViewModel)
    }

    private var popoverSurface: some View {
        LinearGradient(
            colors: [
                Color.nudgewhipBgCanvas,
                Color.nudgewhipBgSurfaceAlt.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
