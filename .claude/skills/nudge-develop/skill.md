---
name: nudge-develop
description: "Nudge 앱의 전체 개발 파이프라인을 조율하는 오케스트레이터. macOS 앱 개발, iOS 연동, 랜딩 페이지, 마케팅 전략, 캐릭터 디자인, 다국어 현지화를 한 번에 실행. 'nudge 개발', '전체 개발', '앱 만들어', '런칭 준비', '다국어', '현지화' 요청 시 반드시 이 스킬을 사용할 것."
---

# Nudge Develop Orchestrator

Nudge(넛지)의 10인 전문가 에이전트 팀을 조율하여 앱 개발 + 마케팅 + 디자인 + 다국어 현지화를 통합 실행하는 오케스트레이터.

## 실행 모드: 에이전트 팀

## 에이전트 구성

### Development Squad (Phase 1~3)

| 팀원 | 에이전트 타입 | 역할 | 스킬 | 출력 |
|------|-------------|------|------|------|
| data-architect | general-purpose | 데이터 모델 & 상태 관리 | (에이전트 정의에 인라인) | `nudge/Shared/Models/*.swift` |
| macos-core | general-purpose | AppKit 시스템 연동 | (에이전트 정의에 인라인) | `nudge/Services/IdleMonitor.swift`, `PermissionManager.swift` |
| swiftui-designer | general-purpose | SwiftUI UI/UX | (에이전트 정의에 인라인) | `nudge/Views/*.swift`, `Services/AlertManager.swift` |
| cloudkit-sync | general-purpose | CloudKit & iOS 연동 | (에이전트 정의에 인라인) | `nudge/Shared/Services/CloudKitManager.swift` |
| qa-integrator | general-purpose | QA & 통합 테스트 | (에이전트 정의에 인라인) | `nudgeTests/*.swift`, `nudgeUITests/*.swift` |

### Growth & Design Squad (Phase 1~2, Dev와 병렬)

| 팀원 | 에이전트 타입 | 역할 | 스킬 | 출력 |
|------|-------------|------|------|------|
| marketing-strategist | general-purpose | 마케팅 전략 & 카피 | (에이전트 정의에 인라인) | `docs/marketing/*.md` |
| content-strategist | general-purpose | 알림/캐릭터 콘텐츠 | (에이전트 정의에 인라인) | `docs/content/*.md` |
| visual-designer | general-purpose | 캐릭터 & 비주얼 디자인 | (에이전트 정의에 인라인) | `docs/design/*.md` |
| localization | general-purpose | 다국어 현지화 (i18n/l10n) | (에이전트 정의에 인라인) | `nudge/Localizable.xcstrings`, `docs/localization/*.md` |
| web-dev | general-purpose | 랜딩 페이지 구축 | (에이전트 정의에 인라인) | `docs/web/*` |

## 워크플로우

### Phase 1: 준비 & 기반 (병렬 팬아웃)

1. 사용자 입력 분석 — 개발 범위(전체/특정 Phase), 우선순위 파악
2. `_workspace/` 디렉토리 생성
3. PRD(`docs/app/spec.md`)를 `_workspace/00_input/spec.md`에 복사

**팀 구성:**

```
TeamCreate(
  team_name: "nudge-team",
  members: [
    { name: "data-architect", subagent_type: "data-architect", model: "opus" },
    { name: "macos-core", subagent_type: "macos-core", model: "opus" },
    { name: "swiftui-designer", subagent_type: "swiftui-designer", model: "opus" },
    { name: "cloudkit-sync", subagent_type: "cloudkit-sync", model: "opus" },
    { name: "qa-integrator", subagent_type: "qa-integrator", model: "opus" },
    { name: "marketing-strategist", subagent_type: "marketing-strategist", model: "opus" },
    { name: "content-strategist", subagent_type: "content-strategist", model: "opus" },
    { name: "visual-designer", subagent_type: "visual-designer", model: "opus" },
    { name: "localization", subagent_type: "localization", model: "opus" },
    { name: "web-dev", subagent_type: "web-dev", model: "opus" }
  ]
)
```

**작업 등록 (의존성 포함):**

```
TaskCreate([
  # 기반 — 의존성 없음, 가장 먼저 시작
  { title: "SwiftData 모델 설계", description: "FocusSession, UserSettings, PetState, DailyStats 모델 구현. Shared/Models/에 배치.", assignee: "data-architect" },
  { title: "마케팅 전략 수립", description: "런칭 타임라인, 타겟 페르소나, 오픈소스 바이럴 전략, 경쟁 분석", assignee: "marketing-strategist" },
  { title: "캐릭터 & 알림 콘텐츠 기획", description: "가상 펫 설정, 알림 종류, 게이미피케이션 체계, 대사 풀", assignee: "content-strategist" },

  # Core — data-architect 완료 후
  { title: "Idle Detection 구현", description: "NSEvent 전역 모니터링, 무입력 타이머, 임계 시간 로직", assignee: "macos-core", depends_on: ["SwiftData 모델 설계"] },
  { title: "권한 관리 구현", description: "AXIsProcessTrusted 체크, 권한 요청 플로우, graceful degradation", assignee: "macos-core", depends_on: ["SwiftData 모델 설계"] },

  # Visual — content-strategist 완료 후
  { title: "캐릭터 디자인 & 비주얼 시스템", description: "캐릭터 일러스트, 컬러/타이포, 앱 아이콘, 상태별 메뉴바 아이콘", assignee: "visual-designer", depends_on: ["캐릭터 & 알림 콘텐츠 기획"] },

  # Marketing — marketing-strategist 완료 후
  { title: "마케팅 카피 작성", description: "랜딩 페이지, 앱스토어, 소셜 미디어 카피", assignee: "marketing-strategist", depends_on: ["마케팅 전략 수립"] },

  # Localization — content + marketing 완료 후
  { title: "String Catalog 기반 다국어 현지화", description: "한국어/영어 .xcstrings 구축, 용어 통일표, 텍스트 외부화 검수, 번역 메모리 관리", assignee: "localization", depends_on: ["캐릭터 & 알림 콘텐츠 기획", "마케팅 카피 작성"] },

  # UI — core + data + visual + localization 완료 후
  { title: "MenuBarExtra UI 구현", description: "드롭다운 뷰, 타이머 설정, 상태 표시, 휴식 토글", assignee: "swiftui-designer", depends_on: ["Idle Detection 구현", "SwiftData 모델 설계"] },
  { title: "알림 시스템 구현", description: "Flash/Grayscale 오버레이, TTS 음성, 알림 해제 로직", assignee: "swiftui-designer", depends_on: ["Idle Detection 구현", "캐릭터 디자인 & 비주얼 시스템", "String Catalog 기반 다국어 현지화"] },

  # CloudKit — data + core 완료 후
  { title: "CloudKit 동기화 구현", description: "CKRecord 매핑, CKQuerySubscription, APNs 푸시 파이프라인", assignee: "cloudkit-sync", depends_on: ["SwiftData 모델 설계", "Idle Detection 구현"] },

  # Web — marketing + visual + localization 완료 후
  { title: "랜딩 페이지 구축", description: "히어로, 기능 소개, 캐릭터, 대기자 명단, 반응형, 다국어 지원", assignee: "web-dev", depends_on: ["마케팅 카피 작성", "캐릭터 디자인 & 비주얼 시스템", "String Catalog 기반 다국어 현지화"] },

  # QA — 모든 개발 완료 후
  { title: "단위 테스트 작성", description: "모델, IdleMonitor, CloudKitManager, AlertManager 테스트", assignee: "qa-integrator", depends_on: ["Idle Detection 구현", "CloudKit 동기화 구현", "알림 시스템 구현"] },
  { title: "통합 테스트 & 최종 검증", description: "권한 플로우, 이벤트 흐름, 동기화 무결성, 크로스 플랫폼 검증", assignee: "qa-integrator", depends_on: ["단위 테스트 작성"] }
])
```

### Phase 2: 병렬 실행 (팀원 자체 조율)

**두 개의 스쿼드가 병렬로 동시 진행:**

**Development Squad 흐름:**
```
data-architect (모델) → macos-core (코어) → swiftui-designer (UI) → qa-integrator (테스트)
                                  ↘ cloudkit-sync (동기화) ↗
```

**Growth & Design Squad 흐름:**
```
marketing-strategist (전략) → 마케팅 카피 ──────────────┐
content-strategist (콘텐츠) → visual-designer (디자인) ──┼→ localization (현지화) → web-dev (랜딩 페이지)
                                                         │        ↑
                                    marketing-strategist ─┘────────┘
```

**팀원 간 통신 규칙:**
- data-architect → macos-core, cloudkit-sync: 모델 스키마 완성 알림 SendMessage
- macos-core → swiftui-designer: idle 상태 변화 이벤트 SendMessage
- content-strategist → visual-designer: 캐릭터 브리프 SendMessage
- content-strategist → localization: 알림/대사 원문 SendMessage
- marketing-strategist → localization: 마케팅 카피 원문 SendMessage
- localization → swiftui-designer: 하드코딩 문자열 외부화 요청 SendMessage
- localization → web-dev: 랜딩 페이지 번역 파일 SendMessage
- marketing-strategist → web-dev: 카피/CTA SendMessage
- visual-designer → swiftui-designer: 아이콘/컬러 가이드 SendMessage
- qa-integrator → 전원: 버그/이슈 피드백 SendMessage

**산출물 저장:**

| 팀원 | 출력 경로 |
|------|----------|
| data-architect | `nudge/Shared/Models/` |
| macos-core | `nudge/Services/` |
| swiftui-designer | `nudge/Views/`, `nudge/Services/AlertManager.swift` |
| cloudkit-sync | `nudge/Shared/Services/`, `nudge/Shared/Models/` |
| marketing-strategist | `docs/marketing/` |
| content-strategist | `docs/content/` |
| visual-designer | `docs/design/` |
| localization | `nudge/Localizable.xcstrings`, `docs/localization/` |
| web-dev | `docs/web/` |
| qa-integrator | `nudgeTests/`, `nudgeUITests/`, `_workspace/qa_report.md` |

### Phase 3: 통합 & 검증

1. qa-integrator가 모든 모듈 교차 검증 수행
2. 발견된 이슈는 담당 에이전트에게 SendMessage로 피드백
3. 수정 후 재검증 (최대 2회 루프)
4. 빌드 성공 확인: `xcodebuild build`
5. 최종 QA 리포트: `_workspace/qa_report.md`

### Phase 4: 정리

1. 팀원들에게 종료 요청 (SendMessage)
2. 팀 정리 (TeamDelete)
3. `_workspace/` 보존
4. 사용자에게 결과 요약 보고:
   - 구현된 기능 목록
   - 테스트 결과 요약
   - 마케팅 산출물 목록
   - 디자인 에셋 목록
   - 다음 단계 권장 사항

## 데이터 흐름

```
                    ┌─ data-architect ──┬→ macos-core ──┬→ swiftui-designer ─→ qa-integrator
                    │                   └→ cloudkit-sync┘         ↑                    ↑
[PRD] → TeamCreate ─┤                                              │                    │
                    │   marketing-strategist → 카피 ─┐             │                    │
                    ├─ content-strategist → visual-designer ─┼→ localization ─→ web-dev  │
                    │                                       │       ↑          │       │
                    │              marketing-strategist ─────┘───────┘          │       │
                    └──────────────────────────────────────────────────────────┘───────┘
                                                          (QA 피드백 → 전원)
```

## 에러 핸들링

| 상황 | 전략 |
|------|------|
| 에이전트 1명 실패 | 리더가 감지 → SendMessage로 상태 확인 → 재시도 |
| 빌드 실패 | qa-integrator가 원인 분석 → 담당 에이전트에게 SendMessage |
| 마케팅/디자인 지연 | Dev Squad는 독립 진행, Growth Squad 결과는 후속 반영 |
| 팀원 과반 실패 | 사용자에게 알리고 진행 여부 확인 |
| 타임아웃 | 현재까지 수집된 부분 결과 사용, 미완료 명시 |

## 테스트 시나리오

### 정상 흐름
1. 사용자가 "nudge 전체 개발 시작" 요청
2. Phase 1에서 팀 구성 (10명 + 14개 작업)
3. Phase 2에서 Development Squad와 Growth Squad가 병렬 진행
4. Development: 모델 → 코어 → UI/동기화 → QA 순차+병렬
5. Growth: 전략 → 콘텐츠 → 디자인 → 현지화 → 랜딩페이지 순차+병렬
6. Phase 3에서 QA 통합 검증, 빌드 성공
7. Phase 4에서 팀 정리, 결과 요약
8. 예상 결과: 앱 코드 + 테스트 + 마케팅 문서 + 디자인 에셋 + 다국어 현지화 + 랜딩 페이지

### 에러 흐름
1. macos-core가 Accessibility API 에러로 중지
2. qa-integrator가 테스트 실패 감지
3. SendMessage로 macos-core에게 에러 내용 전달
4. macos-core가 graceful degradation으로 수정 (제한 모드 동작)
5. 재테스트 통과 → Phase 3 계속 진행
6. 최종 보고서에 "제한 모드 동작 (전체 기능은 권한 획득 후)" 명시
