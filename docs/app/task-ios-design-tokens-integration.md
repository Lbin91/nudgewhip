# iOS Design Tokens 통합 계획서

**문서 번호**: 15-001
**작성일**: 2026-04-18
**작성자**: swiftui-designer
**상태**: 계획 중

## 1. 개요

### 1.1 배경

`DesignTokens.swift`는 `#if os(macOS)`/`#if os(iOS)` 컴파일 가드를 통해 크로스 플랫폼 대응을 완료했습니다. macOS에서는 `NSColor`를, iOS에서는 `UIColor`를 사용하는 `adaptive()` 함수가 구현되어 있어 Light/Dark 모드 자동 전환을 지원합니다.

### 1.2 현재 상태

iOS 뷰는 모두 기본 SwiftUI 시스템 컬러을 사용 중입니다:

| 뷰 | 현재 배경 | 현재 텍스트/아이콘 |
|---|---|---|
| `HomeView` | `.regularMaterial` | `.secondary` |
| `StatsView` | `.regularMaterial`, `.quaternary` | `.secondary`, `.tertiary` |
| `AlertsView` | 없음 (Spacer) | `.secondary` |
| `SettingsView` | 없음 (List 기본) | `.secondary`, `.orange`, `.yellow` |

### 1.3 적용 목표

macOS와 일관된 시각적 경험을 제공하기 위해 iOS 뷰에도 `DesignTokens.swift`의 토큰을 적용합니다. 이를 통해 다음을 달성합니다:

- 플랫폼 간 브랜드 일관성
- Light/Dark 모드 자동 대응
- 디자인 시스템 문서(`design-system.md`) 준수
- 향후 UI 수정 시 단일 진실 공간(Single Source of Truth) 유지

## 2. 적용 대상별 변경 계획

### 2.1 HomeView

#### 2.1.1 heroStatusCard

| 요소 | 현재 | 변경 |
|---|---|---|
| 배경 | `.regularMaterial` | `Color.nudgewhipBgSurface` |
| 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |
| 제목 텍스트 | `.font(.headline)` | 동일 (색상 시스템 기본) |
| 설명 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| 코너 반경 | `RoundedRectangle(cornerRadius: 16)` | `RoundedRectangle(cornerRadius: NudgeWhipRadius.card)` |
| 세로 패딩 | `.padding(.vertical, 24)` | `.padding(.vertical, NudgeWhipSpacing.s6)` |

#### 2.1.2 todaySummaryGrid (SummaryCard)

| 요소 | 현재 | 변경 |
|---|---|---|
| 배경 | `.regularMaterial` | `Color.nudgewhipBgSurface` |
| 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |
| 값 텍스트 | `.font(.title2.bold())` | 동일 (색상 시스템 기본) |
| 라벨 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| 코너 반경 | `RoundedRectangle(cornerRadius: 12)` | `RoundedRectangle(cornerRadius: NudgeWhipRadius.default)` |
| 세로 패딩 | `.padding(.vertical, 12)` | `.padding(.vertical, NudgeWhipSpacing.s3)` |
| 그리드 간격 | `spacing: 12` | `spacing: NudgeWhipSpacing.s3` |

#### 2.1.3 syncHealthCard

| 요소 | 현재 | 변경 |
|---|---|---|
| 배경 | `.regularMaterial` | `Color.nudgewhipBgSurface` |
| 보더 | 없음 | `.overlay(RoundedRectangle(cornerRadius: NudgeWhipRadius.default).stroke(Color.nudgewhipStrokeDefault, lineWidth: 1))` |
| 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |
| 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| 코너 반경 | `RoundedRectangle(cornerRadius: 12)` | `RoundedRectangle(cornerRadius: NudgeWhipRadius.default)` |
| 패딩 | `.padding()` | `.padding(NudgeWhipSpacing.s4)` |

#### 2.1.4 최상위 VStack

| 요소 | 현재 | 변경 |
|---|---|---|
| 간격 | `spacing: 16` | `spacing: NudgeWhipSpacing.s4` |
| 패딩 | `.padding()` | `.padding(NudgeWhipSpacing.s4)` |

### 2.2 StatsView

#### 2.2.1 rangePicker

| 요소 | 현재 | 변경 |
|---|---|---|
| 스타일 | `.pickerStyle(.segmented)` | 동일 (시스템 기본 사용) |

> **참고**: iOS의 `.segmented` 스타일은 시스템에서 자동으로 다크 모드를 대응하므로 별도의 토큰 적용 없음.

#### 2.2.2 kpiStrip (KPIMiniCard)

| 요소 | 현재 | 변경 |
|---|---|---|
| 배경 | `.regularMaterial` | `Color.nudgewhipBgSurface` |
| 값 텍스트 | `.font(.title3.bold())` | 동일 (색상 시스템 기본) |
| 라벨 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| 코너 반경 | `RoundedRectangle(cornerRadius: 8)` | `RoundedRectangle(cornerRadius: NudgeWhipRadius.default)` |
| 세로 패딩 | `.padding(.vertical, 8)` | `.padding(.vertical, NudgeWhipSpacing.s2)` |
| HStack 간격 | `spacing: 12` | `spacing: NudgeWhipSpacing.s3` |

#### 2.2.3 placeholderChart

| 요소 | 현재 | 변경 |
|---|---|---|
| 채우기 | `.fill(.quaternary)` | `.fill(Color.nudgewhipBgSurfaceAlt)` |
| 보더 | 없음 | `.overlay(RoundedRectangle(cornerRadius: NudgeWhipRadius.default).stroke(Color.nudgewhipStrokeDefault, lineWidth: 1))` |
| 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |
| 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| 코너 반경 | `RoundedRectangle(cornerRadius: 8)` | `RoundedRectangle(cornerRadius: NudgeWhipRadius.default)` |
| 높이 | `.frame(height: 160)` | 동일 |
| VStack 간격 | `spacing: 8` | `spacing: NudgeWhipSpacing.s2` |

#### 2.2.4 footnote

| 요소 | 현재 | 변경 |
|---|---|---|
| 텍스트 | `.foregroundStyle(.tertiary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |

#### 2.2.5 최상위 VStack

| 요소 | 현재 | 변경 |
|---|---|---|
| 간격 | `spacing: 16` | `spacing: NudgeWhipSpacing.s4` |
| 패딩 | `.padding()` | `.padding(NudgeWhipSpacing.s4)` |

### 2.3 AlertsView

#### 2.3.1 빈 상태

| 요소 | 현재 | 변경 |
|---|---|---|
| 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |
| 제목 텍스트 | `.font(.headline)` | 동일 (색상 시스템 기본) |
| 설명 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |

#### 2.3.2 향후 알림 목록 구현 시 (비고)

| 요소 | 예상 토큰 | 용도 |
|---|---|---|
| 경고 배지 | `NudgeWhipContentStateColor.remoteEscalation` | 긴급 원격 알림 |
| 일반 알림 아이콘 | `Color.nudgewhipFocus` | 일반 알림 |
| 시간 텍스트 | `Color.nudgewhipTextMuted` | 시간 표시 |

### 2.4 SettingsView

#### 2.4.1 connectionSection

| 요소 | 현재 | 변경 |
|---|---|---|
| 섹션 보더 | 시스템 기본 | 시스템 기본 (List 자동 처리) |
| 상태 아이콘 (경고) | `.foregroundStyle(.orange)` | `.foregroundStyle(Color.nudgewhipAlert)` |
| 상태 아이콘 (정상) | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipFocus)` |
| 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |

#### 2.4.2 proSection

| 요소 | 현재 | 변경 |
|---|---|---|
| Pro 뱃지 아이콘 | `.foregroundStyle(.yellow)` | `.foregroundStyle(Color.nudgewhipAccent)` |
| 비활성 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |

#### 2.4.3 aboutSection

| 요소 | 현재 | 변경 |
|---|---|---|
| 버전/메뉴 텍스트 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextSecondary)` |
| chevron 아이콘 | `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.nudgewhipTextMuted)` |

#### 2.4.4 settingsRow 함수 수정

**현재 코드:**
```swift
.foregroundStyle(status == .warning ? .orange : .secondary)
```

**변경 후:**
```swift
.foregroundStyle(status == .warning ? Color.nudgewhipAlert : Color.nudgewhipTextSecondary)
```

## 3. NudgeWhipSpacing 적용 요약

| 토큰 | 값 | 적용 위치 |
|---|---|---|
| `NudgeWhipSpacing.s2` | 8pt | KPIMiniCard 세로 패딩, placeholderChart 아이콘-텍스트 간격 |
| `NudgeWhipSpacing.s3` | 12pt | SummaryCard 세로 패딩, SummaryCard/KPIMiniCard 그리드 간격 |
| `NudgeWhipSpacing.s4` | 16pt | 카드 간격, 최상위 패딩 |
| `NudgeWhipSpacing.s6` | 32pt | heroStatusCard 세로 패딩 |

## 4. NudgeWhipRadius 적용 요약

| 토큰 | 값 | 적용 위치 |
|---|---|---|
| `NudgeWhipRadius.default` | 12pt | KPIMiniCard, syncHealthCard, placeholderChart, Settings 요소 |
| `NudgeWhipRadius.card` | 16pt | heroStatusCard |

## 5. 고려 사항

### 5.1 DesignTokens 접근성

- `DesignTokens.swift`는 `nudgewhip/Shared/`에 위치하므로 iOS 타겟(`nudgewhipios`)에서 접근 가능합니다.
- iOS 타겟의 "Link Binary With Libraries" 설정에 `Shared` 모듈이 이미 연결되어 있어야 합니다.
- 현재 프로젝트 구조상 이미 연결되어 있다고 가정합니다 (Xcode Shared Target 구조).

### 5.2 UIKit 의존성 없음

- DesignTokens는 순수 SwiftUI `Color` 타입을 반환합니다.
- `UIColor`는 iOS에서 `Color(uiColor:)`로 래핑되므로 SwiftUI 뷰에서 직접 사용 가능합니다.
- UIKit 뷰 컨트롤러는 사용하지 않으므로 별도의 브리지 불필요.

### 5.3 Dynamic Type 대응

- DesignTokens는 색상, 간격, 반경, 모션만 정의합니다.
- 폰트 크기는 시스템 기본 Dynamic Type을 따릅니다 (`.font(.headline)`, `.font(.caption)` 등).
- 간격 토큰(`NudgeWhipSpacing`)은 고정값이므로 Dynamic Type 최대 확대 시 레이아웃 깨짐 가능성이 있습니다 (9.3 참고).

### 5.4 Dark Mode 자동 대응

- `adaptive()` 함수는 iOS에서 `UIColor { traitCollection in }` 클로저를 사용합니다.
- `traitCollection.userInterfaceStyle == .dark`로 자동 감지하므로 별도의 수동 처리 불필요.
- Light/Dark 모드 전환 시 실시간으로 색상이 변경됩니다.

## 6. Lifecycle

### 6.1 앱 시작 시

- `DesignTokens.swift`의 모든 토큰은 `static let`으로 선언되어 있습니다.
- 첫 접근 시 한 번만 초기화되며, 이후에는 캐시된 값이 재사용됩니다.
- 메모리 오버헤드가 거의 없습니다.

### 6.2 Appearance 변경 시

- iOS는 `traitCollection` 변경 시 `UIColor`의 `dynamicProvider`를 자동으로 호출합니다.
- `adaptive()` 함수가 트리거되어 적절한 색상을 반환합니다.
- SwiftUI는 이를 감지하고 뷰를 자동으로 다시 그립니다 (`.redraw()` 불필요).

## 7. 라벨 문구 변경

- DesignTokens 적용은 시각적 스타일(색상, 간격, 반경)만 변경합니다.
- 모든 라벨 문구는 기존과 동일하게 유지합니다.
- 한국어 로컬라이제이션은 이미 적용되어 있으며, 추가적인 변경 불필요.

## 8. 클릭 시 액션

- 버튼, 토글, 네비게이션 등의 인터랙션 동작은 변경되지 않습니다.
- 시각적 피드백만 향상됩니다 (예: 경고 상태가 더 명확해짐).
- `NudgeWhipMotion` 토큰은 향후 애니메이션 구현 시 사용할 수 있습니다 (현재 범위 제외).

## 9. 예외 처리

### 9.1 DesignTokens 미로드 시

- 토큰은 모두 `static let` 컴파일 타임 상수입니다.
- 런타임에 로드 실패할 가능성이 없으므로 예외 처리 불필요합니다.
- Xcode 빌드 시점에 컴파일 에러로 감지됩니다.

### 9.2 색상 대비 접근성

- `design-system.md`의 7.1 WCAG 2.1 대비율 검증에 따르면:
  - Dark Mode: 모든 조합이 AA (4.5:1) 기준 통과
  - Light Mode: 4개 조합이 AA 미달이나, 이미 수정된 값(`#5F6D82`, `#B84525`, `#167A6C`)이 `DesignTokens.swift`에 적용되어 있음
- **추가 검증 필요**: iOS 시뮬레이터에서 VoiceOver 및 대비율 테스트 수행 권장

### 9.3 Dynamic Type 최대 확대 시

- `NudgeWhipSpacing` 토큰은 고정값(`s1`~`s7`)입니다.
- Dynamic Type 최대 확대(Accessibility Extra Large/Extra Extra Large)에서 레이아웃이 깨질 수 있습니다.
- **대응 방안 (향후 고려)**:
  - `NudgeWhipSpacing`을 `@ScaledMetric` 기반의 계산형 프로퍼티로 변경
  - 또는 iOS 17+의 `.layoutPriority()`와 `.fixedSize()` 조합으로 대응

## 10. 테스트 구현

### 10.1 각 뷰 렌더링 테스트

```swift
// HomeViewTests.swift (새 파일)
import XCTest
import SwiftUI
@testable import nudgewhipios

@MainActor
final class HomeViewTests: XCTestCase {
    func testHeroStatusCardUsesDesignTokens() throws {
        // DesignTokens 색상이 올바르게 적용되었는지 확인
        // 현재 UI 테스트에서는 색상 값 직접 확인 불가
        // 스냅샷 테스트 또는 접근성 라벨 확인으로 대체
    }

    func testSummaryCardUsesDesignTokens() throws {
        // SummaryCard의 spacing과 cornerRadius 검증
    }
}
```

### 10.2 스냅샷 테스트 (향후)

- iOS 17+의 `.snapshot()` 기능 또는 Swift Snapshot Testing 라이브러리 사용
- Light/Dark 모드별 스크린샷 비교
- CI/CD 파이프라인에서 회귀 방지

### 10.3 접근성 테스트

```swift
func testColorContrast() throws {
    // XCUIAccessibilityContrast 속성 확인 (iOS 18+)
    // 또는 수동으로 Xcode Accessibility Inspector 사용
}
```

## 11. 실패 테스트 구현

### 11.1 잘못된 hex 값 전달 시

- DesignTokens의 `adaptive()` 함수는 `String` hex 값을 받습니다.
- 컴파일 타임 상수이므로 런타임 실패 불가능합니다.
- hex 형식이 잘못되면 `Scanner(string: cleaned).scanHexInt64(&rgb)`가 `false`를 반환하고 `rgb`는 `0`으로 남습니다.
- **결과**: 검은색(`#000000`)으로 렌더링되며 앱 크래시는 발생하지 않습니다.

### 11.2 Dark Mode 전환 시 색상 누락

- `adaptive()`를 사용하지 않고 고정 색상을 사용한 경우를 탐지합니다.
- **탐지 방법**:
  ```swift
  // 테스트 코드
  func testAllColorsUseAdaptive() throws {
      // DesignTokens.swift에서 static let 색상만 사용하는지 검증
      // 또는 Lint 규칙으로 강제
  }
  ```

### 11.3 Dynamic Type 최대 확대 시 레이아웃 깨짐

- `NudgeWhipSpacing` 고정값 문제로 인해 레이아웃이 겹칠 수 있습니다.
- **탐지 방법**:
  ```swift
  func testLayoutAtExtraLargeDynamicType() throws {
      // Dynamic Type을 Extra Large로 설정 후 뷰 렌더링
      // 오토레이아웃 제약 조건 위반 확인
  }
  ```

## 12. 완료 기준

- [ ] `HomeView.swift`가 모든 DesignTokens 색상/간격/반경을 사용함
- [ ] `StatsView.swift`가 모든 DesignTokens 색상/간격/반경을 사용함
- [ ] `AlertsView.swift`가 모든 DesignTokens 색상을 사용함
- [ ] `SettingsView.swift`가 모든 DesignTokens 색상을 사용함
- [ ] iOS 시뮬레이터에서 Light Mode 렌더링 확인
- [ ] iOS 시뮬레이터에서 Dark Mode 렌더링 확인
- [ ] iOS 시뮬레이터에서 Light/Dark 모드 전환 시 실시간 색상 변경 확인
- [ ] iOS 17+에서 최소 Dynamic Type 크기로 레이아웃 깨짐 없음 확인
- [ ] Xcode Accessibility Inspector로 색상 대비 검증 (선택 사항)
- [ ] 모든 변경 사항이 Git 커밋됨

## 13. 관련 문서

- [DesignTokens.swift](../../nudgewhip/Shared/DesignTokens.swift) - 크로스 플랫폼 디자인 토큰 구현
- [design-system.md](../design/design-system.md) - 디자인 시스템 스펙
- [HomeView.swift](../../nudgewhipios/Views/HomeView.swift) - 홈 뷰 구현
- [StatsView.swift](../../nudgewhipios/Views/StatsView.swift) - 통계 뷰 구현
- [AlertsView.swift](../../nudgewhipios/Views/AlertsView.swift) - 알림 뷰 구현
- [SettingsView.swift](../../nudgewhipios/Views/SettingsView.swift) - 설정 뷰 구현

## 14. 부록: 변경 전후 비교

### 14.1 HomeView 변경 예시

**변경 전:**
```swift
.background(.regularMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16))
```

**변경 후:**
```swift
.background(Color.nudgewhipBgSurface)
.overlay(RoundedRectangle(cornerRadius: NudgeWhipRadius.card).stroke(Color.nudgewhipStrokeDefault, lineWidth: 1))
```

### 14.2 SettingsView 변경 예시

**변경 전:**
```swift
.foregroundStyle(status == .warning ? .orange : .secondary)
```

**변경 후:**
```swift
.foregroundStyle(status == .warning ? Color.nudgewhipAlert : Color.nudgewhipTextSecondary)
```

---

**문서 기록:**

| 버전 | 날짜 | 변경 내용 | 작성자 |
|---|---|---|---|
| 0.1 | 2026-04-18 | 초안 작성 | swiftui-designer |
