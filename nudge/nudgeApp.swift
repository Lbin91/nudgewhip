//
//  nudgeApp.swift
//  nudge
//
//  Created by Bongjin Lee on 4/2/26.
//

import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    var body: some Scene {
        // 기존의 WindowGroup은 삭제!
        // WindowGroup {
        //     ContentView()
        // }
        
        // 대신 MenuBarExtra를 사용
        MenuBarExtra("Nudge", systemImage: "cursorarrow.and.square.on.square.dashed") {
            // 이 안에 메뉴바 아이콘을 클릭했을 때 나올 UI를 넣어주면 돼.
            ContentView()
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
