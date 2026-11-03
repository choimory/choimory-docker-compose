# 목차

- [개요](#개요)
- [작업 마무리하자](#작업-마무리하자)
  - [작업 요약](#작업-요약)
  - [분석과 구현 흐름](#분석과-구현-흐름)
  - [최종 구성](#최종-구성)
  - [사용 방법](#사용-방법)
  - [주의할 점](#주의할-점)
  - [변경된 파일](#변경된-파일)
- [README 최종 점검](#readme-최종-점검)
  - [답변](#답변)
  - [수정한 내용](#수정한-내용)

---

# 개요

- 개인프로젝트 choimory-dev(member-api, front)를 로컬에서 컨테이너로 띄우는 Docker Compose 작성 작업을 마무리함
- 분석은 plan1~3, 구현은 task1~4에 기록함
- 사용자가 테스트 데이터를 지우고 다시 초기화해 전체 동작을 직접 확인함
- calendar를 DONE으로 변경하고, README.md에는 작업 중 반영해 둔 내용을 최종 확인함

---

# 작업 마무리하자

> 니가 테스트했던 데이터 지우고 다시해서 전체  확인 끝났어 작업 마무리하자

## 작업 요약

`choimory-dev/compose.yaml` 하나로 postgres, redis, member-api, front를 띄우고, 개발 패턴에 따라 profiles와 `--scale`로 필요한 것만 골라 띄울 수 있게 함. 앱 이미지는 각 앱 레포에 새로 작성한 Dockerfile로 빌드함. 함께 choimory-local의 데이터 경로를 `docker_volume/choimory/<서비스>`로 변경함.

## 분석과 구현 흐름

| 단계 | 문서 | 내용 |
| --- | --- | --- |
| 분석 | plan1 | 대상 레포 분석, compose 구조(파일 하나), DB 별도 기동, 컨테이너 이름(`*_choimory-dev`), 볼륨 경로, 이미지 버전, DB 이름(`choimory_dev_member`), Flyway와 database 생성 관계 |
| 구현 | task1 | compose, `.env.example`, 앱 레포 Dockerfile/`.dockerignore`, front `output: "standalone"`, choimory-local 볼륨 경로 변경. 빌드, 기동, 회원가입/로그인, front BFF, 종료까지 테스트 |
| 분석 | plan2 | profile 없이 `down`하면 front가 남는 문제, `--profile`, `--build`, `--rmi local` 정리. 개발 패턴별 profile 재설계(`all`, `db-only`, `back-only`, `front-only` + `--scale`), `COMPOSE_PROFILES` |
| 구현 | task2 | 모든 서비스에 profiles 적용, `COMPOSE_PROFILES=all`, front → member-api 주소를 `host.docker.internal:8080`으로 변경, `required: false`. profile별 대상, `--scale`, compose 밖 member-api 연결, 그냥 `down` 전체 정리 테스트 |
| 분석 | plan3 | 앱 레포 경로가 필요한 경우(빌드할 때만), git 주소 context, build context를 `.env`로 빼는 방법, `:?` 필수 변수, postgres credential 오류 원인 |
| 구현 | task3 | build context를 `${VAR:-기본값}`로 변경, `.env.example`에 주석으로 추가 |
| 구현 | task4 | compose 기본값을 빼고 `${VAR:?메시지}` 필수 변수로 변경, `.env.example`에 값 기재 |

## 최종 구성

| 서비스 | 이미지 | 호스트 바인딩 | container_name | profiles |
| --- | --- | --- | --- | --- |
| postgres | `postgres:16.15-bookworm` | 127.0.0.1:15432 | postgres_choimory-dev | `all`, `db-only`, `back-only` |
| redis | `redis:8.10.3` | 127.0.0.1:16379 | redis_choimory-dev | `all`, `db-only`, `back-only` |
| member-api | 앱 레포 Dockerfile 빌드 | 127.0.0.1:8080 | member-api_choimory-dev | `all`, `back-only` |
| front | 앱 레포 Dockerfile 빌드 | 127.0.0.1:3000 | front_choimory-dev | `all`, `front-only` |

- 데이터: `~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/{postgres,redis}` (bind mount, `down`해도 유지)
- database `choimory_dev_member`는 postgres가 최초 기동 때 만들고, 테이블은 member-api 기동 시 Flyway가 만듦
- front 서버 → member-api는 `host.docker.internal:8080`, 브라우저 → member-api는 `localhost:8080`(빌드 시 번들에 고정)
- 앱 레포 경로는 `.env`의 `MEMBER_API_CONTEXT`, `FRONT_CONTEXT`로만 지정 (compose에서 필수 변수)
- `restart` 정책 없음. 앱 이미지는 `image:` 이름 없이 `choimory-dev-<서비스>:latest`로 만들어짐

## 사용 방법

| 개발 패턴 | 명령 |
| --- | --- |
| 전체를 컨테이너로 확인 | `docker compose up -d` (`COMPOSE_PROFILES=all`일 때) |
| 백엔드를 IDE로 개발 | `docker compose --profile db-only up -d` |
| 프론트를 IDE로 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` |
| 백엔드 전부 IDE + 프론트는 컨테이너 | `docker compose --profile db-only --profile front-only up -d` |
| 특정 백엔드만 IDE, 나머지는 컨테이너 | `docker compose up -d --scale member-api=0` |
| 앱 코드가 바뀌었을 때 | 위 명령에 `--build` |
| 종료 | `docker compose down` (앱 이미지까지 지우려면 `--rmi local`) |

## 주의할 점

- **`COMPOSE_PROFILES`**: profile 없는 `up`/`down`의 대상은 `.env`의 `COMPOSE_PROFILES`를 따름. 현재 사용 중인 `.env`는 `db-only`로 바꿔 두었으므로, 전체를 띄웠다면 `docker compose --profile all down`으로 정리
- **postgres 계정**: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`는 데이터 디렉토리가 비어 있을 때만 적용됨. 이후 바꾸려면 데이터 디렉토리 삭제 또는 `ALTER USER`. 이미지 삭제나 `--build`로는 바뀌지 않음
- **`--build`**: 이미지가 남아 있으면 `--build` 없는 `up`은 예전 코드로 뜸. 덮어쓴 이전 이미지는 `<none>`으로 남으므로 가끔 `docker image prune`
- **IDE 실행 시 접속 주소**: member-api는 DB `localhost:15432`, Redis `localhost:16379` (choimory-local의 5432, 6379가 아님). 포트 3000, 8080은 IDE와 컨테이너가 같으므로 동시에 띄우지 않음
- **choimory-local 데이터 이전**: 볼륨 경로를 `docker_volume/choimory/<서비스>`로 바꿈. 예전 경로의 데이터 이전과 삭제는 각 compose 상단 주석의 순서(down → rsync → up → 확인 → 삭제)대로 사용자가 진행
- **커밋**: 이 레포와 앱 레포 2곳 모두 커밋하지 않음. 앱 레포는 dev 브랜치에 파일만 작성함

## 변경된 파일

**choimory-docker-compose**

| 파일 | 내용 |
| --- | --- |
| `choimory-dev/compose.yaml` | 신규. postgres, redis, member-api, front |
| `choimory-dev/.env.example` | 신규. `COMPOSE_PROFILES`, postgres/redis 계정, `JWT_SECRET`, 앱 레포 경로 |
| `choimory-dev/README.md` | 개요만 있던 문서를 구성, 실행 방법, profiles, 환경변수, 구성 메모로 작성 |
| `choimory-local/{postgres,redis,mysql,elasticsearch}/compose.yaml` | 볼륨 경로를 `docker_volume/choimory/<서비스>`로 변경, 이전 안내 주석 교체 |
| `choimory-local/README.md` | 호스트 데이터 경로, 이전 안내 갱신 |
| `README.md` | 디렉토리 구조, choimory-local 데이터 경로, `# choimory-dev` 섹션 추가 |
| `.agents/histories/calendar.md` | `choimory-dev-docker-compose` 항목 추가 후 DONE |

**choimory-dev-member-api (dev 브랜치)**

| 파일 | 내용 |
| --- | --- |
| `Dockerfile` | 신규. `eclipse-temurin:21.0.13_9-jdk-noble`에서 gradlew bootJar → `21.0.13_9-jre-noble`로 실행 |
| `.dockerignore` | 신규 |

**choimory-dev-front (dev 브랜치)**

| 파일 | 내용 |
| --- | --- |
| `Dockerfile` | 신규. `node:22.23.4-alpine`, standalone 실행 |
| `.dockerignore` | 신규 |
| `next.config.ts` | `output: "standalone"` 추가 |

---

# README 최종 점검

> 수정 진행해주고, readme마다 목차도 만들어줘

## 답변

README 3개(루트, choimory-dev, choimory-local)를 실제 설정과 대조해 점검한 결과를 반영하고, 저장소의 README 5개에 목차를 추가함. choimory-local은 사용자가 이전 안내를 이미 정리해 두어 내용 수정은 없었음.

## 수정한 내용

| 파일 | 내용 |
| --- | --- |
| `README.md` | 개발 패턴 명령 표 아래에 "그냥 `down`은 `COMPOSE_PROFILES=all` 기준, 다른 값이면 `--profile all down`" 주의 추가. 앱 레포 Dockerfile 표의 이미지를 실제 태그(`eclipse-temurin:21.0.13_9-*-noble`, `node:22.23.4-alpine`)로 통일. "profile을 닮" → "profile을 붙임". 도입부에 "choimory-dev는 restart 정책 없음" 추가. 실행 방법 2단계에 `COMPOSE_PROFILES`, `*_CONTEXT` 확인 추가. postgres 계정 변경 시 주의 보강 |
| `choimory-dev/README.md` | 명령 표 아래 `COMPOSE_PROFILES` 주의 추가. "처음 한 번"에 `.env`에서 확인할 값 표 추가. `# 문제 해결` 섹션 추가 (postgres 비밀번호 변경 후 credential 오류: 원인, 이미지/`--build`와 무관한 이유, 데이터 초기화/`ALTER USER` 해결법, 포트 확인 / `MEMBER_API_CONTEXT` 필수 변수 에러) |
| README 5개 | 맨 위에 `# 목차` 추가 (H1~H3, GitHub 앵커 규칙. 같은 제목은 `-1`, `-2`로 구분. 코드 블록 안의 `#` 주석은 제외) |

- 목차 추가 대상: `README.md`, `choimory-local/README.md`, `choimory-dev/README.md`, `choimory-server/README.md`, `choimory-server/samba/README.md`

