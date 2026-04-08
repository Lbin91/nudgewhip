# NudgeWhip Channel Copy (KR)

- Version: 0.1
- Last Updated: 2026-04-08
- Owner: `marketing-strategist`
- Scope: 채널별 공개 베타 홍보 문구 템플릿

## 1. Core Positioning

- NudgeWhip은 딴짓을 막는 앱이 아니라, 딴짓이 시작되는 순간 다시 돌아오게 하는 앱이다.
- macOS 메뉴바에서 작동한다.
- 프라이버시 우선이다.
- 키 입력 내용, 화면 내용, 브라우징 기록을 수집하지 않는다.

## 2. One-Line Copy

- 작업 흐름을 끊지 않고, 딴짓이 시작된 순간 다시 데려오는 macOS 메뉴바 앱
- 입력이 멈춘 순간을 감지해 로컬에서 바로 복귀를 유도하는 attention recall tool
- 차단보다 복귀에 집중한, 프라이버시 우선 macOS 메뉴바 앱

## 3. GitHub Release

### 3.1 짧은 소개

- NudgeWhip은 입력이 멈춘 순간을 감지하고, 작업 흐름이 완전히 무너지기 전에 다시 돌아오게 하는 macOS 메뉴바 앱입니다.
- 모든 감지는 Mac에서 로컬로 처리되며, 키 입력 내용이나 화면 내용을 수집하지 않습니다.

### 3.2 릴리즈 요약

- 메뉴바 기반 idle detection
- top countdown overlay
- visual nudge + notification escalation
- schedule controls
- local daily summary
- 한국어 / 영어 지원

### 3.3 다운로드 안내

- notarized DMG 다운로드
- macOS 15 이상 지원
- 첫 실행 후 Accessibility 권한을 허용하면 전체 기능이 활성화됩니다

## 4. X / Threads

### 4.1 Launch Post

NudgeWhip 공개 베타를 배포했습니다.

macOS 메뉴바에서 입력이 멈춘 순간을 감지하고,
딴짓이 길어지기 전에 다시 작업으로 데려오는 앱입니다.

- privacy-first
- local-first
- no keystroke content
- no screenshots

DMG로 바로 설치할 수 있습니다.

### 4.2 Privacy Angle

NudgeWhip은 Accessibility 권한을 쓰지만,
키 입력 내용이나 화면 내용은 수집하지 않습니다.

전역 입력 활동만 보고,
Mac 안에서 로컬로 idle moment를 감지합니다.

차단 앱이 아니라 복귀 앱에 가깝습니다.

### 4.3 Maker Angle

집중이 깨진 뒤 한참 지나서 후회하는 패턴이 반복돼서 만들었습니다.

NudgeWhip은 딴짓을 “막는” 대신,
작업에서 멀어지는 순간을 감지해서
짧고 즉각적인 복귀 신호를 주는 macOS 메뉴바 앱입니다.

## 5. Product Hunt

### 5.1 Headline

- 딴짓이 시작되면, 바로 돌아오게

### 5.2 Tagline

- 입력이 멈춘 순간을 감지해 작업 복귀를 유도하는 macOS 메뉴바 앱

### 5.3 Short Description

NudgeWhip은 입력이 멈춘 순간을 감지하고, 짧은 시각/알림 개입으로 다시 작업으로 돌아오게 하는 macOS 메뉴바 앱입니다. 모든 감지는 로컬에서 동작하며, 키 입력 내용과 화면 내용은 수집하지 않습니다.

### 5.4 Maker Comment

NudgeWhip은 “차단”보다 “복귀”에 초점을 맞춘 앱입니다.

작업 중 딴짓을 아예 못 하게 만드는 대신,
집중이 흐트러지는 시작 지점을 포착해서
짧고 분명한 신호로 다시 돌아오게 하는 경험을 만들고 싶었습니다.

메뉴바에 머물고,
로컬에서 작동하고,
프라이버시를 해치지 않는 방식으로요.

## 6. Reddit

### 6.1 r/macapps 스타일

NudgeWhip이라는 macOS 메뉴바 앱을 만들었습니다.

입력이 멈춘 순간을 감지해서
딴짓이 길어지기 전에 다시 돌아오게 하는 앱입니다.

Accessibility 권한은 전역 입력 활동 감지에만 사용하고,
키 입력 내용이나 화면 내용은 수집하지 않습니다.

현재 DMG로 설치 가능한 공개 베타 상태입니다.

### 6.2 r/productivity 스타일

저는 차단 앱보다 “복귀 앱”이 더 필요하다고 느꼈습니다.

딴짓을 못 하게 막는 것보다,
딴짓이 시작된 순간 짧게 끊어 주는 게 더 현실적이라고 생각해서
NudgeWhip을 만들었습니다.

macOS 메뉴바에서 동작하고,
idle moment를 로컬에서 감지한 뒤
작업으로 다시 돌아오게 유도합니다.

### 6.3 r/opensource 스타일

NudgeWhip은 SwiftUI + AppKit 기반 macOS 메뉴바 앱입니다.

- MenuBarExtra
- NSEvent global monitoring
- SwiftData
- local-first runtime model
- Sparkle 기반 업데이트 준비

현재 공개 베타로 배포 중입니다.

## 7. Hacker News

### 7.1 Title

- Show HN: NudgeWhip, a privacy-first macOS menu bar app that brings you back when attention drifts

### 7.2 First Comment

NudgeWhip은 딴짓을 막는 앱이 아니라,
딴짓이 시작되는 순간 다시 돌아오게 하는 앱입니다.

macOS 메뉴바에서 동작하고,
전역 입력 활동만 사용해 idle moment를 감지합니다.

키 입력 내용, 화면 내용, 브라우징 기록은 수집하지 않습니다.

공개 베타 DMG로 설치 가능합니다.

## 8. Community Post

### 8.1 Korean Dev Community

NudgeWhip 공개 베타를 배포했습니다.

집중이 깨지는 시작 지점을 감지해서
짧은 시각/알림 개입으로 다시 작업에 복귀하게 만드는
macOS 메뉴바 앱입니다.

프라이버시 우선 설계로,
입력 내용이나 화면 내용은 수집하지 않습니다.

### 8.2 macOS User Community

NudgeWhip은 메뉴바에 조용히 머물다가
입력이 멈춘 순간을 감지해
딴짓이 길어지기 전에 다시 돌아오게 하는 앱입니다.

과하게 막지 않고,
짧고 날카롭게 복귀를 유도하는 쪽에 가깝습니다.

## 9. Landing / Download Section

### 9.1 Hero

- 딴짓이 시작되면, 바로 돌아오게
- 작업 흐름을 끊지 않고 복귀를 유도하는 macOS 메뉴바 앱

### 9.2 Supporting

- 로컬 감지
- 프라이버시 우선
- notarized DMG 배포
- 한국어 / 영어 지원

## 10. Reuse Notes

- “차단 앱이 아니라 복귀 앱” 문장은 여러 채널에서 반복 사용 가능
- 프라이버시 문구는 항상 함께 붙인다
- 설치 가능 상태에서는 반드시 `DMG로 설치 가능` 문구를 넣는다
- 공개 베타 단계에서는 기능 나열보다 설치 가능 + 차별점 + 프라이버시를 우선한다
