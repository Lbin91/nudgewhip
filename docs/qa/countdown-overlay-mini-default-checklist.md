# Countdown Overlay Mini Default Checklist

- Version: draft-1
- Last Updated: 2026-04-12
- Owner: engineering / QA
- Scope: 신규 설치에서 mini overlay 기본값 체감 검토

## 1. Purpose

- 신규 설치 사용자의 기본 overlay variant를 `mini`로 두는 결정이 실제로 자연스러운지 검토하기 위한 체크리스트다.
- 기존 사용자 마이그레이션은 이 문서 범위 밖이며, 오직 `fresh install` 기준으로 본다.

## 2. Preconditions

- 신규 설치 또는 완전 초기화 상태
- onboarding first-run flow부터 다시 진입
- KR/EN 각각 최소 1회 확인

## 3. Checklist

### 3.1 First Impression

- [ ] overlay가 처음부터 부담스럽지 않다
- [ ] mini라서 정보가 부족하다고 느껴지지 않는다
- [ ] “이 정도면 켜 둬도 되겠다”는 인상을 준다

### 3.2 Comprehension

- [ ] countdown 숫자가 바로 읽힌다
- [ ] idle threshold 대비 overlay 목적이 이해된다
- [ ] settings에서 standard로 바꿀 수 있다는 흐름이 납득 가능하다

### 3.3 Control

- [ ] overlay를 끄는 경로를 찾기 어렵지 않다
- [ ] hover affordance가 있다면 close button을 무리 없이 발견할 수 있다
- [ ] settings 진입 없이도 제어감이 있다고 느껴진다

### 3.4 Language

- [ ] KR에서 용어가 어색하지 않다
- [ ] EN에서 overly technical 하지 않다
- [ ] `countdown overlay` 표현이 위치 중립적으로 이해된다

### 3.5 Comparison Against Standard

- [ ] standard보다 mini가 확실히 덜 거슬린다
- [ ] standard보다 정보 손실이 치명적이지 않다
- [ ] 신규 설치 기본값으로는 mini가 더 타당하다

## 4. Suggested Test Prompts

실사용 감각 메모를 남길 때 아래 질문을 사용:

- 처음 봤을 때 overlay를 끄고 싶었는가?
- mini가 너무 작은가, 아니면 적당한가?
- standard를 기본값으로 두는 편이 더 설득력 있는가?
- hover close가 편한가, 아니면 오히려 방해가 되는가?

## 5. Decision Rule

### Keep `mini` as new-install default

- mini가 첫인상 부담을 줄이고
- 가독성/제어감이 허용 범위 내이며
- standard 대비 장점이 분명할 때

### Reconsider default

- mini가 너무 작거나
- close affordance 발견성이 낮거나
- 신규 사용자가 처음부터 standard를 더 안정적으로 느낄 때

## 6. Exit Criteria

- KR/EN 각각 1회 이상 점검
- fresh install 흐름에서 mini 기본값 체감 메모 확보
- keep / reconsider 결론 중 하나를 기록
