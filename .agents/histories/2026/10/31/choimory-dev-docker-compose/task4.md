# 목차

- [개요](#개요)
- [:? 방식으로 작업 시작](#-방식으로-작업-시작)
  - [답변](#답변)
  - [수정한 파일](#수정한-파일)
  - [테스트 결과](#테스트-결과)
  - [참고](#참고)

---

# 개요

- plan3에서 정한 대로 앱 레포 경로(`build.context`)를 compose 기본값 없이 `.env`로만 지정하게 바꿈 (task3의 "compose 기본값 + `.env.example` 주석" 방식을 대체)
- compose에는 필수 변수(`${VAR:?메시지}`)로 두어, 값이 없으면 원인을 알려주며 멈추게 함
- `.env.example`은 주석을 풀고 값을 넣음. 사용 중인 `.env`에도 같은 값을 추가함
- 커밋하지 않음

---

# :? 방식으로 작업 시작

> :? 방식으로 작업 시작

## 답변

compose, `.env.example`, `.env`, README 수정과 테스트를 마침. 경로 해석, 빌드, 변수가 없을 때의 에러 메시지까지 확인함.

## 수정한 파일

| 파일 | 내용 |
| --- | --- |
| `choimory-dev/compose.yaml` | member-api `context: ${MEMBER_API_CONTEXT:?.env에 MEMBER_API_CONTEXT(member-api 레포 경로)를 설정하세요}`, front `context: ${FRONT_CONTEXT:?.env에 FRONT_CONTEXT(front 레포 경로)를 설정하세요}`. 필수 변수로 둔 이유와 "값이 없으면 db-only, down도 멈춘다"는 주의를 주석으로 추가. 상단 주석을 ".env로 지정"으로 수정 |
| `choimory-dev/.env.example` | `MEMBER_API_CONTEXT`, `FRONT_CONTEXT` 주석을 풀고 기본 경로를 값으로 넣음. "지우면 모든 compose 명령이 멈춘다"는 주의 추가 |
| `choimory-dev/.env` | 끝에 두 변수 추가 (gitignore 대상). 추가하지 않으면 compose가 바로 멈추기 때문 |
| `choimory-dev/README.md` | 환경변수 표의 기본값을 실제 경로로, 설명에 "필수 값" 추가. 구성 메모의 "앱 레포 경로"를 필수 변수 방식으로 갱신 |
| `README.md` | choimory-dev 개요의 `build.context` 설명과 환경변수 표 갱신 |

## 테스트 결과

| 항목 | 방법 | 결과 |
| --- | --- | --- |
| 문법 | `docker compose config -q` | 통과 |
| 경로 해석 | `docker compose --profile all config --format json`의 `build.context` | `IdeaProjects/choimory-dev/choimory-dev-member-api`, `.../choimory-dev-front` |
| 빌드 | `docker compose --profile all build` | member-api, front 모두 Built |
| 변수가 없을 때 | `.env`에서 `_CONTEXT` 줄만 뺀 임시 env 파일(scratchpad, 확인 후 삭제)로 `--env-file <임시파일> --profile db-only config -q` | `required variable MEMBER_API_CONTEXT is missing a value: .env에 MEMBER_API_CONTEXT(member-api 레포 경로)를 설정하세요`로 멈춤 (db-only도 막히는 것 확인) |

## 참고

- 작업 중 확인해 보니 사용 중인 `.env`의 `COMPOSE_PROFILES`가 `db-only`로 바뀌어 있었음 (사용자가 변경). 그대로 두고, 테스트에는 `--profile all`을 직접 붙여 확인함
  - 이 상태에서는 profile 없는 `docker compose up -d`, `docker compose down`이 postgres, redis만 대상으로 함. 전체를 띄웠다면 `docker compose --profile all down`으로 정리해야 함
- 테스트 시점에 사용자가 띄워 둔 `postgres_choimory-dev`, `redis_choimory-dev`가 실행 중이었고, 건드리지 않음
