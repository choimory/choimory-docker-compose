# 목차

- [개요](#개요)
- [작업 시작](#작업-시작)
  - [답변](#답변)
  - [작성, 수정한 파일](#작성-수정한-파일)
    - [choimory-docker-compose](#choimory-docker-compose)
    - [choimory-dev-member-api (dev 브랜치)](#choimory-dev-member-api-dev-브랜치)
    - [choimory-dev-front (dev 브랜치)](#choimory-dev-front-dev-브랜치)
  - [작업 중 정한 점](#작업-중-정한-점)
  - [테스트 결과](#테스트-결과)
  - [남은 것과 확인할 점](#남은-것과-확인할-점)

---

# 개요

- plan1에서 정한 내용으로 choimory-dev compose, 앱 레포 Dockerfile을 작성하고 choimory-local 데이터 경로를 변경함
- 테스트는 사용자 요청에 따라 실제 빌드, 기동, API 호출, 종료까지 직접 수행함
- 커밋은 하지 않음 (choimory-docker-compose, 앱 레포 모두)
- calendar를 TASK로 변경

---

# 작업 시작

> 테스트도 해줘 작업 시작해

## 답변

계획한 파일 작성과 테스트를 마침. 테스트는 두 실행 모드 기동, 회원가입, 로그인, front BFF 로그인, 종료 정리까지 모두 통과함.

## 작성, 수정한 파일

### choimory-docker-compose

| 파일 | 내용 |
| --- | --- |
| `choimory-dev/compose.yaml` | 신규. postgres, redis, member-api, front(`profiles: ["front"]`) |
| `choimory-dev/.env.example` | 신규. POSTGRES_USER/PASSWORD/DB, REDIS_USER/PASSWORD, JWT_SECRET |
| `choimory-dev/README.md` | 개요만 있던 문서에 구성, 실행 방법, 환경변수, down 옵션 정리 |
| `choimory-local/{postgres,redis,mysql,elasticsearch}/compose.yaml` | 볼륨 경로를 `docker_volume/choimory/<서비스>`로 변경 |
| `choimory-local/{postgres,redis,elasticsearch}/compose.yaml` | 상단 주석을 docker run 이전 방법에서 "예전 경로 → 새 경로 이전 방법(down → rsync → up)"으로 교체 |
| `choimory-local/README.md` | 호스트 데이터 경로 트리, 이전 안내, 작성 규칙 문구 수정 |
| `README.md` | 디렉토리 구조, choimory-local 데이터 경로 수정, `# choimory-dev` 섹션 추가 |

### choimory-dev-member-api (dev 브랜치)

| 파일 | 내용 |
| --- | --- |
| `Dockerfile` | 신규. `eclipse-temurin:21.0.13_9-jdk-noble`에서 `./gradlew :member-api:bootJar -x test` → `eclipse-temurin:21.0.13_9-jre-noble`로 실행. 비root 계정 `app` |
| `.dockerignore` | 신규. 빌드 결과물, `.gradle`, IDE, `.agents`, 문서 제외 (`docs/flyway`는 포함) |

### choimory-dev-front (dev 브랜치)

| 파일 | 내용 |
| --- | --- |
| `Dockerfile` | 신규. `node:22.23.4-alpine` 3단계(deps → builder → runner). standalone 결과물만 실행, 비root 계정 `node` |
| `.dockerignore` | 신규. `node_modules`, `.next`, `env/`, `.env*`, 테스트, IDE 제외 |
| `next.config.ts` | `output: "standalone"` 추가 |

## 작업 중 정한 점

- **이미지 태그**: Docker Hub에서 확인한 버전으로 고정 (2026-10-31 기준)
  - member-api: `eclipse-temurin:21.0.13_9-jdk-noble` / `-jre-noble`. Gradle 이미지 대신 프로젝트 wrapper(8.14.2)를 그대로 씀
  - front: `node:22.23.4-alpine`. 로컬 Node(22.17)와 같은 메이저
- **Gradle 의존성 캐시**: BuildKit 캐시 마운트(`/root/.gradle`)로 재빌드 시 다시 받지 않게 함
- **front lock 파일**: `package-lock.json`이 front `.gitignore` 대상이라 없는 환경도 있어서, 있으면 `npm ci`, 없으면 `npm install`
- **redis healthcheck 추가**: plan에서는 postgres만 계획했으나, member-api가 Redis에도 의존하므로 redis도 healthcheck 후 기동하게 함
- **compose 환경변수 이름**: `.env`는 postgres, redis 이미지 변수 이름을 쓰고, member-api에는 compose에서 `RDB_*`, `REDIS_*`, `JWT_SECRET`으로 다시 매핑함
- **choimory-local 이전 주석**: docker run에서 옮기는 작업은 이미 끝났으므로, 지금 필요한 "예전 경로 → 새 경로" 이전 방법으로 교체함. mysql은 예전 경로에 데이터가 없어 경로만 변경

## 테스트 결과

테스트용 `choimory-dev/.env`는 `.env.example`을 복사해 비밀번호와 JWT 키를 랜덤값(`openssl rand`)으로 넣어 만듦. (gitignore 대상)

| 항목 | 명령 / 방법 | 결과 |
| --- | --- | --- |
| choimory-local compose 문법 | 각 디렉토리 `docker compose config -q` | 통과 (mysql은 `.env`가 없어 변수 경고만 나옴) |
| choimory-dev compose 문법 | `docker compose --profile front config -q` | 통과. 기본 모드는 postgres, redis, member-api / front profile 시 front 추가 |
| 이미지 빌드 | `docker compose --profile front build` | member-api(최초 약 2분 30초), front 모두 성공 |
| 기본 모드 기동 | `docker compose up -d` | postgres, redis healthy 후 member-api 기동. 프로필 `local`, Flyway V1~V3 적용, `Started ... in 5.3 seconds` |
| 회원가입 (postgres) | `POST localhost:8080/v1/member/join` | 201, `Access-Control-Allow-Origin: http://localhost:3000` 확인 |
| 로그인 (JWT, Redis) | `POST localhost:8080/v1/login` | 200, accessToken 발급. Redis `dbsize` 1 (Refresh Token 저장) |
| 전체 모드 기동 | `docker compose --profile front up -d` | front 기동, `GET localhost:3000/` 200 |
| front 서버 → member-api | `POST localhost:3000/api/auth/login` | 200, `refresh_token` 쿠키 발급. 컨테이너 안에서 `member-api:8080`으로 호출 성공 |
| 브라우저 번들 주소 | `.next/static`에서 주소 검색 | `localhost:8080`만 포함, 내부 주소(`member-api:8080`)는 없음 |
| 종료 | `docker compose --profile front down --rmi local` | 컨테이너 4개, 네트워크, member-api/front 이미지 삭제. postgres/redis 이미지와 `docker_volume/choimory-dev/{postgres,redis}` 데이터는 유지 |
| choimory-local 영향 | `docker ps` | `postgres_choimory`, `redis_choimory`, `elasticsearch_choimory`는 영향 없이 계속 실행 중 |

## 남은 것과 확인할 점

- **테스트 데이터**: `choimory_dev_member`에 테스트 계정 `compose-test@example.com`이 남아 있음. 필요 없으면 계정을 지우거나 `docker_volume/choimory-dev/postgres`를 삭제해 초기화
- **테스트용 `.env`**: `choimory-dev/.env`에 랜덤 비밀번호가 들어 있음. 그대로 써도 되고, 바꾸려면 postgres는 데이터 디렉토리를 초기화하거나 `ALTER USER`로 변경
- **choimory-local 데이터 이전 (사용자 실행)**: 실행 중인 컨테이너는 아직 예전 경로를 마운트 중. 각 서비스에서 `down` → `rsync -a --delete` → `up -d` → 확인 → 예전 디렉토리 삭제 순서로 진행 (각 compose 상단 주석 참고)
- **커밋**: 앱 레포 2곳(dev 브랜치)과 이 레포 모두 커밋하지 않음
