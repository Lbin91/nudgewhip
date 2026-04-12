# Countdown Overlay Visual QA Matrix

- Version: draft-1
- Last Updated: 2026-04-12
- Owner: engineering / QA
- Scope: countdown overlay corner placement and visual stability

## 1. Purpose

- 이 문서는 countdown overlay의 실제 화면 배치가 corner/variant/디스플레이 환경에 따라 어색해지지 않는지 검증하기 위한 시각 QA 매트릭스다.
- 특히 `Dock magnify`, `Dock 위치`, `multi-monitor`, `mini / standard` 조합에서 overlay가 거슬리거나 잘못 배치되는지 확인한다.

## 2. Test Axes

필수 축:

- variant: `standard`, `mini`
- corner: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`
- display: `single monitor`, `dual monitor`
- Dock: `bottom`, `left`, `right`
- Dock magnify: `off`, `on`
- appearance: `light`, `dark`

권장 추가 축:

- accessibility: `increase contrast`, `reduce transparency`
- runtime state: `monitoring`, `limitedNoAX`, `pausedManual`, `alerting`

## 3. Priority Scenarios

### 3.1 Single Monitor Baseline

- [ ] standard / topLeft
- [ ] standard / bottomRight
- [ ] mini / topLeft
- [ ] mini / bottomRight

확인 항목:

- `visibleFrame` 기준으로 코너에 붙어 보이는가
- 메뉴바/Dock과 시각적으로 과하게 충돌하지 않는가
- 텍스트 가독성이 유지되는가

### 3.2 Dock Magnify Stress Cases

- [ ] Dock bottom + magnify on + bottomLeft
- [ ] Dock bottom + magnify on + bottomRight
- [ ] Dock left + magnify on + topLeft
- [ ] Dock right + magnify on + topRight

확인 항목:

- magnify 중에도 overlay가 Dock과 너무 붙어 보이지 않는가
- Dock hover 확대 시 overlay가 시각적으로 흔들리거나 가려 보이지 않는가
- mini variant가 standard보다 확실히 덜 거슬리는가

### 3.3 Multi-monitor Primary-screen Contract

- [ ] 듀얼 모니터에서 overlay가 primary screen에만 표시되는가
- [ ] primary screen 변경 후 배치가 예상대로 바뀌는가
- [ ] secondary monitor 작업 중에도 overlay 위치 정책이 혼란스럽지 않은가

확인 항목:

- 현재 계약인 `NSScreen.main ?? NSScreen.screens.first` 기준과 실제 체감이 크게 어긋나지 않는가
- 사용자 입장에서 “어느 화면에 뜨는지” 설명 가능성이 있는가

## 4. Failure Signatures

- Dock과 너무 붙어 보여 답답함
- top corner에서 메뉴바와 간섭하는 느낌
- bottom corner에서 Dock 확대 중 시각 충돌
- multi-monitor에서 overlay 위치가 예측 불가능하게 느껴짐
- mini 텍스트 가독성 저하
- light mode에서 대비 부족

## 5. Pass / Needs Follow-up Rules

### Pass

- 기본 4코너 사용이 모두 무난하다
- Dock magnify stress case에서 심한 충돌이 없다
- multi-monitor 정책이 현재 버전에서 수용 가능하다

### Needs Follow-up

- 특정 Dock 위치에서만 반복적으로 거슬림
- mini의 특정 코너에서 시인성이 불충분
- primary-screen 정책 때문에 실제 사용 맥락에서 혼란이 큼

## 6. Evidence to Capture

- corner별 스크린샷
- Dock magnify on/off 비교 스크린샷
- dual-monitor 사진 또는 녹화
- variant별 주관 평가 메모:
  - `거슬림`
  - `가독성`
  - `배치 납득 가능성`

## 7. Recommended Output

각 조합마다 아래 형태로 기록:

- Environment
- Variant
- Position
- Dock config
- Result: `pass / acceptable / follow-up`
- Notes

## 8. Exit Criteria

- 단일 모니터 baseline 4건 완료
- Dock magnify stress case 4건 완료
- multi-monitor primary-screen 계약 검토 완료
- follow-up이 생기면 구체적 코너/환경/증상까지 기록
