# Nudge Open-Core License and Trademark Policy

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `marketing-strategist` + project maintainers
- Status: product policy draft, not legal advice

## 1. Purpose

- 이 문서는 Nudge의 open-core 범위와 비공개 범위를 분리하고, 라이선스 방향, 상표 사용 규칙, 기여/IP 원칙, 배포 가드레일을 정리한다.
- 목표는 외부 공개 코드와 내부 제품 자산을 혼동하지 않게 하고, 출시 전후의 운영 판단 기준을 고정하는 것이다.
- 법률 자문 문서가 아니라 제품 운영 정책 문서로 사용한다.

## 2. Core Policy Summary

- 공개 대상은 `idle detection` 핵심 엔진과 기본 macOS shell, 기본 알림 로직이다.
- 비공개 대상은 iOS companion, CloudKit sync 구현, Pro 전용 예외 규칙, 브랜드 자산, 캐릭터 자산이다.
- 제품명 `Nudge`와 관련 로고, 메뉴바 아이콘, 캐릭터 이름, 마케팅 그래픽은 상표 및 브랜드 자산으로 취급한다.
- 공개 코드와 비공개 자산은 저장소, 폴더, README, 배포 산출물 수준에서 명확히 구분한다.

## 3. Open-Core Scope

### 3.1 Public Candidate Scope

- `IdleMonitor`의 전역 입력 감지 및 one-shot idle timer 로직
- Accessibility 권한 상태 처리와 제한 모드 표시
- 기본 시각 넛지와 간단한 TTS 트리거 로직
- 상태 머신의 공용 계약과 테스트 가능한 인터페이스
- 로컬 전용 상태 저장 및 요약 계산의 비민감한 부분

### 3.2 Private Scope

- iOS companion 기능과 Push/CloudKit 동기화 구현
- Pro 전용 상태 전이, 화이트리스트 세부 규칙, 휴식 모드 정책
- 프리미엄 카피, 가격 실험, 전환 퍼널 세부 데이터
- 캐릭터 artwork, 애니메이션 원본, 브랜드 가이드의 내부 버전
- 상표 사용 정책과 출시 메시지의 최종 승인본

### 3.3 Boundary Rule

- 코드가 공개되어도 제품 기능의 모든 상세가 공개되는 것은 아니다.
- 공개 범위는 구현 패턴과 core logic 중심으로 제한한다.
- 사용자 데이터를 직접 다루는 세부 sync/entitlement logic은 공개 범위에 넣지 않는다.

## 4. License Direction

### 4.1 Default Direction

- 공개 코드의 기본 라이선스 방향은 permissive license를 우선 검토한다.
- 1차 권장안은 `Apache-2.0`이다.
- 이유는 외부 기여 수용, 특허 관련 명시성, 상표/브랜딩과의 분리를 운영하기 쉽기 때문이다.

### 4.2 Alternative Evaluation

- 배포 단순성을 우선하면 `MIT`도 후보가 될 수 있다.
- 외부 재사용 통제보다 기여자 보호와 명시성을 우선하면 `Apache-2.0`을 유지한다.
- copyleft 계열은 현재 open-core 운영 목적과 충돌 가능성이 있어 기본 방향이 아니다.

### 4.3 Release Rule

- 최종 SPDX 식별자는 public release 직전 확정한다.
- release 전에 `LICENSE`, `NOTICE`, 저장소 README, 기여 가이드가 서로 충돌하지 않아야 한다.

## 5. Trademark Policy

### 5.1 Trademark Ownership

- `Nudge`, 넛지 로고, 캐릭터명, 메뉴바 아이콘, 런칭 카피에서 반복되는 제품 식별 요소는 브랜드 자산으로 본다.
- 브랜드 자산은 공개 코드 라이선스와 독립적으로 관리한다.

### 5.2 Permitted Use

- 사용자는 저장소 링크, 버그 리포트, 리뷰, 포트폴리오 설명에서 제품명을 사실적으로 언급할 수 있다.
- 오픈소스 기여자는 `based on Nudge` 수준의 출처 표기를 할 수 있다.
- 제품 기능 설명에서 브랜드명을 사용할 때는 제품 공식 명칭을 그대로 유지해야 한다.

### 5.3 Restricted Use

- 공식 승인 없이 유사 제품, 포크, 사칭 배포물에 `Nudge` 명칭이나 혼동 가능한 로고를 사용하지 않는다.
- 내부 승인 없는 변형 로고, 캐릭터 파생 자산, 마케팅 문구를 외부 배포물의 대표 브랜드로 사용하지 않는다.
- App Store, GitHub README, 웹 랜딩에서 실제 제품 범위를 넘어서는 제휴 또는 보증 표현을 쓰지 않는다.

### 5.4 Enforcement Principle

- 상표 보호는 과도한 통제보다 사용자 혼동 방지를 우선한다.
- 경고, 수정 요청, 사용 범위 명확화 순서로 대응한다.

## 6. Contribution and IP Rules

### 6.1 Contribution Model

- 외부 기여는 이슈, PR, 문서 제안, 버그 리포트, 번역 개선을 포함한다.
- 핵심 로직 변경은 코드 리뷰를 거쳐야 한다.
- 기여자는 자신이 올리는 코드와 텍스트가 제3자 권리를 침해하지 않음을 전제로 한다.

### 6.2 IP Handling

- 외부 기여물은 프로젝트가 재배포 가능한 형태로 취급한다.
- 기여자의 저작권 표시는 필요에 따라 유지하되, 제품 브랜드 및 내부 자산 권리는 분리한다.
- 외부 기여가 브랜드 자산, 캐릭터, 가격 전략, Pro 운영 규칙을 자동으로 소유하지는 않는다.

### 6.3 Submission Rules

- 기여자는 기존 라이선스 방향과 프로젝트 정책에 동의해야 한다.
- 익명 또는 무단 복제 출처가 불분명한 콘텐츠는 병합하지 않는다.
- 번역/카피/디자인 제안도 실제 배포 전 검수 대상으로 본다.

### 6.4 Preferred Governance

- 공개 저장소에는 `CONTRIBUTING.md`와 `CODE_OF_CONDUCT.md`를 둘 수 있다.
- 필요 시 `DCO` 또는 `CLA`를 도입하지만, 현재 문서는 도입 여부를 확정하지 않는다.

## 7. Distribution Rules

### 7.1 Public Distribution

- 공개 저장소에는 open-core 범위 코드와 개발에 필요한 최소 문서만 둔다.
- README는 공개 범위와 비공개 범위를 명확히 구분해야 한다.
- 릴리즈 아티팩트는 소스 코드와 브랜드 자산을 분리해서 배포한다.

### 7.2 Private Distribution

- Pro 기능, 내부 실험 문구, 브랜드 가이드는 private repository 또는 별도 private folder에서 관리할 수 있다.
- 내부 배포물에는 캐릭터 원본, 마케팅 실험, 가격 실험 결과를 포함할 수 있다.

### 7.3 Build and Packaging Guardrails

- 오픈 저장소 빌드에서 private key, entitlement, brand-only asset이 요구되면 안 된다.
- public build는 기능 검증이 가능해야 하지만, Pro 기능 구현의 모든 디테일을 포함할 필요는 없다.
- 공개 배포 시 외부 사용자가 혼동할 수 있는 internal-only feature flag는 기본 비활성화를 원칙으로 한다.

## 8. Branding Guardrails

- 제품명, 로고, 캐릭터, 톤앤매너는 상표/브랜드 관리 범위에 속한다.
- open-core README와 웹 랜딩은 제품을 설명할 수 있지만, 내부 미확정 계획을 확정된 사실처럼 말하면 안 된다.
- `attention recall tool`, `privacy-first`, `Mac only`, `Mac + iPhone` 같은 포지셔닝 문구는 정해진 맥락에서만 사용한다.
- 공개 문서에서 브랜드 자산을 재사용할 때는 승인된 최신 버전을 사용한다.

## 9. Review and Approval Gates

- 공개 전 체크리스트:
  - 공개 코드와 비공개 코드 경계가 분리되었는가
  - 상표 자산과 코드 라이선스가 충돌하지 않는가
  - README가 공개 범위를 과장하지 않는가
  - 기여 규칙이 외부 사용자를 혼동시키지 않는가
  - 배포물에 private asset이 섞이지 않는가

- 브랜드 승인 체크리스트:
  - 제품명 표기가 일관적인가
  - 로고/아이콘 사용이 최신 승인본인가
  - 외부 파트너가 혼동할 만한 문구가 없는가

## 10. Open Questions

- 최종 공개 라이선스를 `Apache-2.0`으로 확정할지 `MIT`로 단순화할지
- 외부 기여를 받기 위한 `DCO` 또는 `CLA`를 도입할지
- 브랜드 자산을 별도 private asset repository로 분리할지
- 공개 저장소에서 Pro 기능에 대한 stub만 둘지, 완전 제거할지

