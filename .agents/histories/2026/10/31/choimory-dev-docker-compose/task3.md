# 목차

- [개요](#개요)
- [build context를 .env로 빼기](#build-context를-env로-빼기)
  - [답변](#답변)
  - [수정한 파일](#수정한-파일)
  - [테스트 결과](#테스트-결과)

---

# 개요

- plan3에서 정한 대로 choimory-dev compose의 앱 레포 경로(`build.context`)를 `.env`로 바꿀 수 있게 함
- `.env.example`에는 값 대신 주석으로만 둠. 평소엔 compose의 기본 경로를 쓰고, 레포가 다른 위치일 때만 주석을 풀어 씀
- 사용 중인 `.env`는 수정하지 않음 (값이 없으면 기본 경로를 쓰므로 그대로 동작)
- 커밋하지 않음

---

# build context를 .env로 빼기

> 주석으로만 두고 작업 시작

## 답변

compose, `.env.example`, README 수정과 테스트를 마침. 기본값, 환경변수, env 파일 세 경우 모두 경로가 의도대로 풀리고, 빌드도 정상 동작함.

## 수정한 파일

| 파일 | 내용 |
| --- | --- |
| `choimory-dev/compose.yaml` | member-api `context: ${MEMBER_API_CONTEXT:-../../../choimory-dev/choimory-dev-member-api}`, front `context: ${FRONT_CONTEXT:-../../../choimory-dev/choimory-dev-front}`. 상단 주석에 `.env`로 바꾸는 방법과 "경로는 빌드할 때만 필요"를 추가 |
| `choimory-dev/.env.example` | 맨 아래에 `MEMBER_API_CONTEXT`, `FRONT_CONTEXT`를 주석으로 추가 (기본값 설명, 상대경로 기준, 절대경로 가능) |
| `choimory-dev/README.md` | 환경변수 표에 두 변수 추가. 구성 메모의 "앱 레포 경로"를 `.env`로 바꾸는 방법과 경로가 필요한 경우로 갱신 |
| `README.md` | choimory-dev 개요의 `build.context` 설명 갱신, 환경변수 표에 두 변수 추가 |

## 테스트 결과

| 항목 | 방법 | 결과 |
| --- | --- | --- |
| 문법 | `docker compose config -q` | 통과 |
| 기본값 (`.env`에 변수 없음) | `config --format json`의 `build.context` 확인 | `IdeaProjects/choimory-dev/choimory-dev-member-api`, `.../choimory-dev-front` (기존과 같음) |
| 환경변수로 지정 | `MEMBER_API_CONTEXT=/tmp/other/member-api FRONT_CONTEXT=../front-elsewhere docker compose config` | 절대경로는 그대로, 상대경로는 `compose.yaml` 위치 기준으로 풀림 |
| env 파일로 지정 | scratchpad에 `MEMBER_API_CONTEXT=...-moved`만 담은 임시 env 파일을 만들어 `--env-file .env --env-file <임시파일>`로 확인 | member-api만 지정한 경로, front는 기본 경로 |
| 빌드 | `docker compose build` | member-api, front 모두 Built (캐시 사용) |

- 컨테이너는 띄우지 않음 (빌드만 확인)
