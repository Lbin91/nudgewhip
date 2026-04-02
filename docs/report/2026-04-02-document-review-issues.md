# 문서 검토 및 이슈 리포트

- 작성일: 2026-04-02
- 목적: `spec.md` 기준 하위 문서 정합성, 기술 제약, 타겟 유저 적합성 교차 검증
- 상태: 2026-04-02 반영 검토 완료

## 1. 크리티컬한 이슈 (논리적 모순 및 런칭 블로커)

**"무료 사용자에게 휴식을 제안하지만, 휴식 기능은 유료 전용인 상태"**
- **관련 문서:** `docs/app/spec.md`, `docs/qa/acceptance-matrix.md`
- **내용:** `spec.md`의 피로도 관리(Fatigue Guardrails) 정책을 보면, 오탐이나 반복 알림 시 사용자에게 **휴식 모드를 제안(Break Suggestion)** 하도록 되어 있습니다. 또한 QA 매트릭스에서는 이 기능이 Phase 1 (무료 버전) 대상이라고 명시되어 있습니다.
- **문제점:** 하지만 **'수동 휴식 모드(Break Mode)' 자체는 Phase 2 (Pro/유료 전용 기능)** 로 엄격하게 격리되어 있습니다. Phase 1 사용자가 빈번한 알림에 지쳐 휴식 제안 버튼을 클릭하더라도, 앱 내에 프로세스를 처리할 `pausedManual` 휴식 상태가 해금되어 있지 않기 때문에 앱이 동작할 수 없는 교착 상태(Dead End)에 빠지게 됩니다. 
- **해결 제안:** 피로도 관리용 단기 휴식(ex. 5분 일시 정지)은 Free 버전에 최소한의 기능으로 포함하고, 커스텀 시간이 가능한 캘린더 기반의 강력한 휴식 모드만 Pro 버전에 두는 식으로 기획 수정이 시급합니다.
- **판정:** 수용
- **반영 결과:** `spec.md`, `notification-types.md`, `dialogue-pool.md`, `acceptance-matrix.md`에서 Phase 1의 `breakSuggestion`을 `break mode` 진입이 아니라 민감도 조정/알림 강도 완화/도움말 안내로 축소했다. `pausedManual`은 계속 Phase 2 전용으로 유지한다.

## 2. 기획서(`spec.md`)와 하위 문서 간 어긋난 내용

**"존재하지 않는 1.5차 알림 (GentleNudge 오해석)"**
- **관련 문서:** `docs/content/notification-types.md`, `docs/architecture/state-machine-contract.md`
- **내용:** `spec.md` 및 아키텍처 문서에서는 알림 에스컬레이션을 1차(perimeter pulse = GentleNudge)와 2차(강한 시각 알림 = StrongNudge)로 명확히 나누고 있습니다.
- **문제점:** 알림 카피를 정의한 `notification-types.md`의 매핑 테이블(Section 10)에서는 1차를 `idle_notice`, 2차를 `strong_warning`으로 자의적으로 배정하고, **갑자기 기획서에 없는 1.5차 경고단계를 만들어 `GentleNudge`를 중간 단계에 매핑**해버렸습니다. 이는 상태 머신(State Machine) 설계 및 데이터 기록 스펙과 전면 충돌합니다.
- **판정:** 수용
- **반영 결과:** `notification-types.md`에서 1.5차 단계를 삭제했다. `GentleNudge`는 `perimeterPulse`의 1차 넛지로, `gentle_warning`은 richer surface variation으로만 남겼다.

## 3. 애플 공식 문서 생태계 및 기술 제약에서 벗어난 기능

**① CloudKit 비동기 푸시의 치명적 한계 (Rate Limit)**
- **관련 문서:** `docs/architecture/cloudkit-sync-contract.md`
- **내용:** 문서를 보면 Pro 사용자의 iOS 원격 알림(RemoteEscalation)을 백그라운드 푸시(Silent Push, `content-available`)를 통해 전달한 뒤 앱이 최종 상태를 복구시킬 것이라고 가정하고 있습니다.
- **문제점:** 애플의 정책상 **백그라운드/Silent 푸시는 1시간에 2~3회 수준으로 매우 엄격하게 빈도를 제한(Rate-limit)** 하며, 기기 배터리 및 시스템 상태에 따라 아예 무시되기도 합니다. 실시간에 가까운 "돌아오세요" 알림을 Silent Push로 구현하면 iOS 기기에는 알림이 울리지 않아 기능이 작동하지 않습니다.
- **해결 제안:** CloudKit의 `CKNotificationInfo`에 `alertBody`를 명시하여 시스템이 직접 화면에 알림을 띄우는 Visible Push 형태로 아키텍처를 변경해야 합니다.
- **판정:** 부분 수용
- **반영 결과:** `cloudkit-sync-contract.md`에서 `RemoteEscalation`의 기본 전달 수단을 사용자 가시 알림으로 명시했고, content-available 전용 silent push는 보조 최적화로만 남겼다. 다만 최종 iOS 구현 세부는 구현 단계에서 검증한다.

**② 존재하지 않는 Accessibility 권한 거부(Denied) 이벤트**
- **관련 문서:** `docs/architecture/state-machine-contract.md`
- **내용:** 해당 문서에서는 `accessibilityDenied`를 시스템 이벤트로 받고 "Polling 타이머는 사용하지 않는다"라고 명시했습니다.
- **문제점:** macOS의 손쉬운 사용(`AXIsProcessTrusted`) API는 권한 부여/거부에 대한 명시적인 Event/Notification 콜백을 시스템 차원에서 제공하지 않습니다. 권한 창을 닫았는지, 클릭해 승인했는지 확인하려면 **반드시 Polling 방식을 쓰거나 앱이 다시 활성화(Foreground) 될 때 재검사하도록 예외 처리를 해야 합니다**. 현재 아키텍처 문서의 무조건적인 Polling 금지 규칙은 macOS의 기술 한계와 모순됩니다.
- **판정:** 수용
- **반영 결과:** `state-machine-contract.md`에서 `accessibilityDenied`를 OS 실시간 이벤트가 아닌 앱 재검사로 발행하는 합성 이벤트로 재정의했다. 또한 polling 금지 규칙이 idle detection deadline에만 적용됨을 명시했다.

## 4. 타겟 유저(지식노동자)의 니즈와 거리가 있는 것들

**"죄책감을 유발해버리는 감정 모델과 다소 유아틱한 펫 성장 시스템"**
- **관련 문서:** `docs/content/character-design-brief.md`
- **내용:** 1차 초기 페르소나는 '개발자, 디자이너, 창업자' 등의 프로페셔널한 지식노동자이며, `spec.md`의 대원칙 중 하나가 **"죄책감 유발 금지"** 입니다.
- **문제점:** 
  1. 캐릭터 상태 테이블을 보면, 타이머가 길어질 때 펫이 **슬픈 표정(`sad` + 걱정 톤)** 을 짓도록 기획되어 있습니다. 개발자가 잠시 키보드에서 손을 떼고 로직을 깊게 구상하거나 연습장에 스케치를 그리고 있을 때 나타나는 '날 슬프게 쳐다보는 펫'은 유저에게 불쾌감과 죄책감을 심어주게 되어 핵심 철학과 정면으로 충돌합니다.
  2. "새싹(`sprout`)에서 성장(`guide`)" 하는 레벨링 시스템은 타겟 유저인 프로페셔널 그룹에게는 과도하게 캐주얼하고 유치하게 다가갈 수 있어 몰입(Focus)이라는 툴의 본질을 흐릴 우려가 높습니다.
- **해결 제안:** '슬픔' 감정을 기획에서 완전히 덜어내고 '담백하고 중립적인 관찰' 수준으로 낮춰야 합니다. 가벼운 펫 캐릭터 모드와 완전히 추상화된 시각 넛지 모드(미니멀한 기하학 도형 등)를 선택할 수 있게 옵션화할 필요가 있습니다.
- **판정:** 부분 수용
- **반영 결과:** `character-design-brief.md`, `character-sprite-spec.md`, `notification-types.md`, `spec.md`에서 `sad` 표현을 `concern` 중심으로 완화하고, 펫 레이어를 선택 사항으로 두며 미니멀/추상 시각 넛지 모드를 허용하도록 정리했다. 성장 단계 자체는 유지하되 기본 출시에서는 과도한 전면 노출을 피한다.
