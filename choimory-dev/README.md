# 목차

- [개요](#개요)
- [디렉토리 구조](#디렉토리-구조)
- [서비스 목록](#서비스-목록)
  - [호스트 데이터 경로](#호스트-데이터-경로)
- [실행 방법](#실행-방법)
  - [처음 한 번](#처음-한-번)
  - [개발 패턴별 명령](#개발-패턴별-명령)
  - [특정 서비스만 빼기 (--scale)](#특정-서비스만-빼기---scale)
  - [이미지 빌드, 정리 옵션](#이미지-빌드-정리-옵션)
  - [IDE로 띄울 때 접속 주소](#ide로-띄울-때-접속-주소)
  - [상태 확인](#상태-확인)
- [profiles](#profiles)
  - [설정한 profile](#설정한-profile)
  - [모든 서비스에 profile을 단 이유와 COMPOSE_PROFILES](#모든-서비스에-profile을-단-이유와-compose_profiles)
  - [profile과 --scale을 나눈 이유](#profile과---scale을-나눈-이유)
- [down 옵션별 정리 범위](#down-옵션별-정리-범위)
- [환경변수 (.env)](#환경변수-env)
- [문제 해결](#문제-해결)
  - [postgres 비밀번호를 바꿨는데 접속이 안 됨 (credential 오류)](#postgres-비밀번호를-바꿨는데-접속이-안-됨-credential-오류)
  - [required variable MEMBER_API_CONTEXT is missing a value](#required-variable-member_api_context-is-missing-a-value)
- [구성 메모](#구성-메모)

---

# 개요

- 개인프로젝트 choimory-dev의 로컬 구동을 위한 compose 관리
- 앱 레포 위치: `~/choimory_workspace/IdeaProjects/choimory-dev`
  - `choimory-dev-member-api`: 회원 API (Spring Boot, Java 21)
  - `choimory-dev-front`: 프론트 (Next.js)
  - `choimory-dev-sender-queue`: 미개발이라 아직 compose에 없음
- 앱 이미지는 각 앱 레포의 `Dockerfile`로 빌드함
- 개발할 때만 띄우는 용도. `restart` 정책이 없고, 끌 때 컨테이너를 지움. 앱 이미지는 남겨 다음 기동에 재사용
- IDE로 개발 중인 서비스는 빼고 나머지만 컨테이너로 띄울 수 있도록 profiles와 `--scale`로 구성함

---

# 디렉토리 구조

```txt
choimory-dev/
├── compose.yaml    # postgres, redis, member-api, front
└── .env.example
```

- `.env`는 `.env.example`을 복사해 만들고, 루트 `.gitignore`로 커밋에서 제외됨

---

# 서비스 목록

| 서비스 | 이미지 | 호스트 바인딩 | container_name | profiles | 비고 |
| --- | --- | --- | --- | --- | --- |
| postgres | `postgres:16.15-bookworm` | 127.0.0.1:15432 | postgres_choimory-dev | `all`, `db-only`, `back-only` | database `choimory_dev_member` |
| redis | `redis:8.10.3` | 127.0.0.1:16379 | redis_choimory-dev | `all`, `db-only`, `back-only` | ACL 계정 인증 |
| member-api | `choimory-dev-member-api/Dockerfile` 빌드 | 127.0.0.1:8080 | member-api_choimory-dev | `all`, `back-only` | Spring 프로필 `local` |
| front | `choimory-dev-front/Dockerfile` 빌드 | 127.0.0.1:3000 | front_choimory-dev | `all`, `front-only` | |

- postgres, redis는 choimory-local(5432, 6379)과 겹치지 않도록 호스트 포트를 15432, 16379로 씀
- 이미지 버전은 choimory-local과 맞춤
- 새 백엔드(예: sender-queue)는 `all`, `back-only`를 달아 추가함

## 호스트 데이터 경로

```txt
~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/
├── postgres/
└── redis/
```

- `down` 해도 데이터는 이 경로에 남음. 초기화하려면 down 후 해당 디렉토리를 직접 삭제

---

# 실행 방법

## 처음 한 번

```bash
cp .env.example .env
```

`.env`에서 아래 값을 확인, 수정함.

| 변수 | 확인할 것 |
| --- | --- |
| `POSTGRES_PASSWORD`, `REDIS_PASSWORD` | `changeme`를 실제 값으로 변경. postgres는 최초 기동 전에 정해야 함 ([문제 해결](#문제-해결) 참고) |
| `JWT_SECRET` | 32바이트 이상으로 변경 (`openssl rand -base64 48`) |
| `COMPOSE_PROFILES` | profile 없이 실행할 때의 기본 모드. 기본 `all` |
| `MEMBER_API_CONTEXT`, `FRONT_CONTEXT` | 앱 레포 위치. 기본은 `../../../choimory-dev/<레포>` |

## 개발 패턴별 명령

| 개발 패턴 | 명령 | 뜨는 것 | IDE로 띄울 것 |
| --- | --- | --- | --- |
| 전체를 컨테이너로 확인 | `docker compose up -d` | 전부 | 없음 |
| 백엔드를 IDE로 개발 | `docker compose --profile db-only up -d` | postgres, redis | 백엔드 |
| 프론트를 IDE로 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` | postgres, redis, member-api | front |
| 백엔드 전부 IDE + 프론트는 컨테이너 | `docker compose --profile db-only --profile front-only up -d` | postgres, redis, front | 백엔드 |
| 특정 백엔드만 IDE, 나머지는 컨테이너 | `docker compose up -d --scale member-api=0` | member-api만 빼고 전부 | member-api |
| 종료 (모든 경우) | `docker compose down` | - | - |

- 종료를 그냥 `docker compose down`으로 하는 것은 `.env`의 `COMPOSE_PROFILES`가 `all`일 때 기준. 다른 값(예: `db-only`)으로 바꿨다면 그 profile 범위만 정리되므로, 전체를 띄웠을 때는 `docker compose --profile all down`으로 정리
- `db-only`를 먼저 띄워 둔 상태에서 `--profile front-only up -d`를 따로 실행해도 됨. 이미 떠 있는 DB는 그대로 유지됨
- IDE의 front와 컨테이너 front는 둘 다 3000 포트를 쓰므로 동시에 띄우지 않음. member-api도 8080으로 같음

## 특정 서비스만 빼기 (`--scale`)

```bash
# member-api만 IDE로 돌리고 나머지는 컨테이너로
docker compose up -d --scale member-api=0

# 여러 개를 빼려면 이어 씀 (예: member-api, front 둘 다 IDE로)
docker compose up -d --scale member-api=0 --scale front=0

# profile과 같이 쓸 수도 있음 (예: 백엔드 중 member-api만 빼고 프론트 개발 확인)
docker compose --profile back-only up -d --scale member-api=0
```

- `--scale <서비스>=0`은 해당 서비스의 컨테이너 수를 0으로 맞추는 compose 기본 기능. 이미 떠 있으면 내림
- 다시 넣으려면 `--scale` 없이 `up -d`를 다시 실행

## 이미지 빌드, 정리 옵션

```bash
docker compose up -d --build              # 앱 코드가 바뀌어 이미지를 새로 빌드할 때 (어느 패턴 명령에나 붙임)
docker compose up -d --build member-api   # member-api만 다시 빌드해서 교체
docker compose down --rmi local           # 직접 빌드한 앱 이미지까지 지우고 싶을 때
```

| 옵션 | 언제 쓰나 | 동작 |
| --- | --- | --- |
| `up --build` | 앱 코드(member-api, front)가 바뀌었을 때 | 이미지를 다시 빌드해 같은 태그(`latest`)로 덮어쓰고, 바뀐 컨테이너만 교체. 바뀐 게 없으면 캐시로 몇 초 안에 끝남 |
| `down --rmi local` | 앱 이미지까지 지워 디스크를 비우고 싶을 때 | `image:` 이름 없이 직접 빌드한 이미지(member-api, front)만 삭제. postgres, redis 이미지는 유지 |

- `--build` 없이 `up`하면 남아 있는 앱 이미지를 그대로 씀. 코드를 고친 뒤 `--build`를 빼면 **예전 코드로 뜸**
- 앱 이미지가 없으면(처음 기동, `--rmi local`로 지운 뒤) `--build`가 없어도 자동으로 빌드함
- `--build`로 덮어쓰면 이전 이미지는 태그 없는(`<none>`) 이미지로 남음. 쌓이면 가끔 `docker image prune`으로 정리
- 재빌드는 Gradle 의존성과 레이어 캐시가 남아 있어 빠름. 빌드 캐시가 쌓이면 가끔 `docker builder prune`으로 정리

## IDE로 띄울 때 접속 주소

| IDE로 띄우는 것 | 설정할 주소 |
| --- | --- |
| member-api | DB `localhost:15432` (database `choimory_dev_member`), Redis `localhost:16379`. 계정, 비밀번호, JWT 키는 `.env`와 같은 값 |
| front | `MEMBER_API_BASE_URL`, `NEXT_PUBLIC_MEMBER_API_BASE_URL` 모두 `http://localhost:8080` (front의 `env/.env.local` 기본값) |

- choimory-local의 DB(5432, 6379)가 아닌 choimory-dev의 DB(15432, 16379)에 붙는지 확인
- IDE의 member-api는 8080으로 띄움. 컨테이너 front가 `host.docker.internal:8080`으로 호출하므로 포트가 같아야 함

## 상태 확인

- 상태: `docker compose ps`
- 로그: `docker compose logs -f member-api`
- member-api 기동 확인: 로그의 `Successfully applied N migrations`(최초 기동)와 `Started ChoimoryDevMemberApiApplication`
- DB(DataGrip): `localhost:15432`, database `choimory_dev_member`, 계정은 `.env`의 `POSTGRES_USER`
- Redis: `docker exec -it redis_choimory-dev redis-cli --user <계정> --pass <비밀번호> --no-auth-warning ping` (`PONG`)

---

# profiles

`--profile`은 compose 파일 안의 서비스 중 어떤 것을 이번 명령에 포함할지 고르는 스위치. `up`뿐 아니라 `down`, `ps`, `logs`, `build` 등 모든 compose 명령에 똑같이 적용됨.

## 설정한 profile

| profile | 포함 서비스 | 용도 |
| --- | --- | --- |
| `all` (기본) | postgres, redis, member-api, front | 전체 |
| `db-only` | postgres, redis | 백엔드를 IDE로 개발할 때 |
| `back-only` | postgres, redis, member-api | 프론트를 IDE로 개발할 때 |
| `front-only` | front | 백엔드 전부를 IDE로 돌리면서 프론트만 컨테이너로 띄울 때. DB는 `db-only`로 따로 띄움 |

- `--profile`은 여러 개를 함께 줄 수 있고, 각 profile에 포함된 서비스를 합친 것이 대상이 됨 (예: `--profile db-only --profile front-only`)

## 모든 서비스에 profile을 단 이유와 `COMPOSE_PROFILES`

- `profiles:`가 없는 서비스는 어떤 profile을 줘도 항상 뜸. `db-only`처럼 일부만 띄우려면 모든 서비스에 profile이 있어야 함
- 대신 모든 서비스에 profile이 있으면, profile을 지정하지 않은 명령은 아무 서비스도 대상으로 삼지 않음
- 그래서 `.env`에 `COMPOSE_PROFILES=all`을 기본값으로 둠. compose는 `.env`를 자동으로 읽으므로 `docker compose up -d`가 `docker compose --profile all up -d`와 같게 동작함

| | `.env`에 `COMPOSE_PROFILES=all` 없음 | 있음 |
| --- | --- | --- |
| `docker compose up -d` | 아무것도 안 뜸 | 전체 기동 |
| `docker compose down` | 아무것도 안 내려감 | 전체 정리 |
| `docker compose --profile db-only up -d` | DB만 | DB만 (명령의 `--profile`이 `.env`보다 우선) |

- 종료는 어떤 패턴으로 띄웠든 `docker compose down` 하나로 전부 정리됨 (기본 profile `all`이 모든 서비스를 포함하므로)
- 내 기본 모드를 바꾸고 싶으면 `.env`의 `COMPOSE_PROFILES` 값을 바꿈 (예: `db-only`). 이때는 `down`도 그 profile 범위만 정리하므로 주의

## profile과 `--scale`을 나눈 이유

- profile은 "더하기"만 됨. 특정 서비스를 빼는 profile(`no-member-api` 등)을 만들려면 그 이름을 나머지 모든 서비스에 하나하나 달아야 하고, 서비스가 늘수록 조합이 늘어남
- 그래서 자주 쓰는 묶음(`db-only`, `back-only`, `front-only`)만 profile로 두고, 특정 서비스 빼기는 설정 없이 어떤 서비스에나 쓸 수 있는 `--scale <서비스>=0`을 씀

---

# `down` 옵션별 정리 범위

| 대상 | `down` | `down -v` | `down --rmi local` | `down --rmi all` |
| --- | --- | --- | --- | --- |
| 컨테이너, 네트워크 | 삭제 | 삭제 | 삭제 | 삭제 |
| named/익명 볼륨 | 유지 | 삭제 | 유지 | 유지 |
| bind mount 데이터 | 유지 | 유지 | 유지 | 유지 |
| 직접 빌드한 이미지 (member-api, front) | 유지 | 유지 | 삭제 | 삭제 |
| 받아온 이미지 (postgres, redis) | 유지 | 유지 | 유지 | 삭제 |

---

# 환경변수 (.env)

| 변수 | 기본값(.env.example) | 설명 |
| --- | --- | --- |
| `COMPOSE_PROFILES` | `all` | profile 미지정 시 적용할 기본 profile. 명령의 `--profile`이 우선 |
| `POSTGRES_USER` | `choimory` | postgres 계정. member-api의 `RDB_USER`로도 쓰임 |
| `POSTGRES_PASSWORD` | `changeme` | 위 계정 비밀번호 |
| `POSTGRES_DB` | `choimory_dev_member` | member-api용 database |
| `REDIS_USER` | `choimory` | redis ACL 계정 |
| `REDIS_PASSWORD` | `changeme` | 위 계정 비밀번호. `$`는 쓰지 않음 |
| `JWT_SECRET` | `changeme` | member-api JWT 서명 키 (HS256, 32바이트 이상) |
| `MEMBER_API_CONTEXT` | `../../../choimory-dev/choimory-dev-member-api` | member-api 레포 위치 (`build.context`). 필수 값 |
| `FRONT_CONTEXT` | `../../../choimory-dev/choimory-dev-front` | front 레포 위치 (`build.context`). 필수 값 |

- postgres 계정과 database는 데이터 디렉토리가 비어 있을 때(최초 기동)만 적용됨. 이후 비밀번호를 바꾸려면 DB 안에서 `ALTER USER`로 변경
- Redis 계정은 기동할 때마다 `command`로 설정되므로 `.env`를 바꾸고 다시 `up -d` 하면 바로 적용됨

---

# 문제 해결

## postgres 비밀번호를 바꿨는데 접속이 안 됨 (credential 오류)

- **원인**: postgres는 데이터 디렉토리가 비어 있을 때(최초 기동)만 `.env`의 `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`를 적용함. 이후 `.env`를 바꿔도 DB 안의 계정 정보는 그대로임
- **이미지 삭제나 `--build`로는 해결되지 않음**: 계정 정보는 이미지가 아니라 bind mount된 데이터 디렉토리(`docker_volume/choimory-dev/postgres`)에 저장되어 있어서, 컨테이너나 이미지를 다시 만들어도 그대로 남음
- Redis는 기동할 때마다 `command`로 계정을 다시 설정하므로 이 문제가 없음

해결 방법은 둘 중 하나.

```bash
# A. 데이터 초기화 (데이터를 버려도 될 때). 테이블은 member-api 기동 시 Flyway가 다시 만듦
docker compose --profile all down
rm -rf ~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/postgres
docker compose up -d

# B. 데이터 유지하고 비밀번호만 변경 (컨테이너 안에서는 비밀번호 없이 접속됨)
docker exec -it postgres_choimory-dev psql -U <POSTGRES_USER> -d postgres -c "ALTER USER <POSTGRES_USER> PASSWORD '<새 비밀번호>';"
```

- DataGrip 포트가 `15432`인지도 확인. `5432`로 붙으면 choimory-local의 postgres로 접속됨

## `required variable MEMBER_API_CONTEXT is missing a value`

- `.env`에 `MEMBER_API_CONTEXT`, `FRONT_CONTEXT`가 없을 때 나는 에러. compose에 기본값이 없는 필수 변수라 `db-only`, `down` 등 모든 명령이 멈춤
- `.env.example`의 두 줄을 `.env`에 복사해 넣음

---

# 구성 메모

- **서비스 간 통신**
  - member-api → DB, Redis: compose 기본 네트워크의 서비스 이름(`postgres:5432`, `redis:6379`)
  - front → member-api: `host.docker.internal:8080`. 호스트의 8080을 거치므로 member-api가 컨테이너든 IDE든 같은 주소로 닿음
- **member-api 환경변수**: `application-*.yml`의 자리표시자(`${rdb-host}` 등)를 대문자+언더스코어 환경변수(`RDB_HOST` 등)로 주입함. Spring이 relaxed binding으로 찾으므로 앱 설정 수정이 필요 없음
- **DB 생성 순서**: postgres 이미지가 `POSTGRES_DB`로 database를 만들고, member-api가 healthcheck 통과 후 기동하면서 Flyway로 테이블과 초기 데이터를 만듦
- **front의 member-api 주소**
  - 서버(Route Handler): `MEMBER_API_BASE_URL=http://host.docker.internal:8080` (실행 시 환경변수. 바꿔도 재빌드 불필요)
  - 브라우저: `NEXT_PUBLIC_MEMBER_API_BASE_URL=http://localhost:8080` (빌드 인자. 번들에 고정되므로 바꾸면 다시 빌드)
  - member-api CORS(local 프로필)가 `http://localhost:3000`을 허용하므로 front는 3000 포트를 유지
- **front의 `depends_on: member-api`는 `required: false`**: `front-only`, `--scale member-api=0`처럼 member-api 컨테이너 없이 front를 띄우는 경우가 있기 때문
- **`image:` 이름 없음**: `down --rmi local`은 `image:` 이름이 없는 빌드 이미지만 지우므로 member-api, front에는 이름을 붙이지 않음. 이미지 이름은 compose가 `<프로젝트>-<서비스>:latest`(`choimory-dev-member-api:latest`)로 붙임
- **앱 레포 경로**: `build.context`는 `.env`의 `MEMBER_API_CONTEXT`, `FRONT_CONTEXT`로만 지정함 (compose에 기본값 없음)
  - 상대경로는 `compose.yaml` 위치 기준(터미널 위치 아님)이며 절대경로도 됨
  - compose에는 필수 변수(`${MEMBER_API_CONTEXT:?메시지}`)로 둠. 값이 없으면 빈 경로가 `choimory-dev/` 자신으로 풀려 "Dockerfile이 없다"는 엉뚱한 에러가 나므로, 대신 "`.env`에 설정하라"는 메시지로 바로 멈추게 함
  - 변수 치환은 compose 파일 전체에 먼저 적용되므로, 값이 없으면 빌드와 상관없는 `db-only`, `down`도 함께 멈춤
  - 경로는 이미지를 빌드할 때만 필요함. 이미지가 남아 있으면 `--build` 없는 `up`은 레포가 없어도 되고, `db-only`는 레포와 상관없음
