# Countdown Overlay Mini Hover Affordance Experiment

- Version: draft-1
- Last Updated: 2026-04-12
- Status: active experiment
- Owner: engineering / product

## 1. Goal

- mini overlay가 너무 미니멀해져서 `바로 끄는 경로`가 사라진 문제를 완전히 설정 메뉴에만 의존하지 않고 보완할 수 있는지 확인한다.
- 단, standard overlay처럼 상시 close button을 복원하지는 않는다.

## 2. Hypothesis

- mini overlay는 기본 상태에서는 숫자/상태 토큰만 보여주는 편이 덜 거슬린다.
- 하지만 커서를 올렸을 때만 작은 close affordance를 보여주면:
  - 평소 시각 부담은 유지하면서
  - 필요할 때 즉시 끌 수 있는 통제감도 제공할 수 있다.

## 3. Experiment Shape

- 기본 상태: text-only mini chip
- hover 상태: trailing close affordance 노출
- mini overlay는 hover 감지를 위해 mouse events를 받는다

## 4. Explicit Trade-off

이 실험은 mini overlay가 작은 영역이라도 마우스 이벤트를 가로챌 수 있다는 비용을 수반한다.

즉, 이번 실험의 핵심 질문은 아래다.

- `hover affordance의 편의`가 `작은 클릭 가로채기 비용`보다 큰가?

## 5. Success Signals

- 사용자가 mini overlay를 굳이 settings로 들어가지 않고도 바로 끌 수 있다
- close affordance가 기본 상태의 시각적 부담을 크게 늘리지 않는다
- 96x32 크기에서도 조작이 어렵지 않다

## 6. Failure Signals

- hover하지 않아도 mini overlay가 이미 방해물처럼 느껴진다
- 작은 overlay가 코너 클릭을 방해한다고 느껴진다
- close affordance hit target이 너무 작다
- hover 진입/이탈이 불안정하다

## 7. What To Observe During QA

- hover 진입 속도
- close affordance 발견 가능성
- 클릭 성공률
- overlay가 underlying app click을 방해하는 체감
- bottom corner + Dock magnify 환경에서의 사용성

## 8. Likely Outcomes

### Keep

- hover affordance가 유의미하고 방해가 적다

### Revise

- affordance는 필요하지만 hit target 또는 위치를 키워야 한다

### Revert

- mouse event interception 비용이 예상보다 크다

## 9. Exit Decision

실험 후 아래 셋 중 하나로 정리한다.

- ship as-is
- keep behind follow-up polish
- remove and return to settings-only dismissal
