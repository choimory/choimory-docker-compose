# 목차

- [개요](#개요)
- [plan1 확인](#plan1-확인)
  - [답변](#답변)
  - [현재 상태](#현재-상태)
    - [choimory-dev-front](#choimory-dev-front)
    - [choimory-dev-member-api](#choimory-dev-member-api)
    - [공통](#공통)
  - [진행 계획 (안)](#진행-계획-안)
  - [결정이 필요한 것](#결정이-필요한-것)
- [추가1](#추가1)
- [추가1 확인](#추가1-확인)
  - [답변](#답변-1)
  - [compose 구조: 전체 파일 + 서비스별 파일](#compose-구조-전체-파일--서비스별-파일)
  - [서비스별 구성](#서비스별-구성)
    - [postgres / redis (choimory-dev 전용)](#postgres--redis-choimory-dev-전용)
    - [member-api](#member-api)
    - [front](#front)
  - [남은 결정](#남은-결정)
- [추가2](#추가2)
- [추가2 확인](#추가2-확인)
  - [답변](#답변-2)
  - [1. compose 파일 하나 + profiles](#1-compose-파일-하나--profiles)
  - [2. 컨테이너 이름](#2-컨테이너-이름)
  - [3. 휘발성 운용](#3-휘발성-운용)
  - [4. Dockerfile (앱 레포 작업)](#4-dockerfile-앱-레포-작업)
  - [5. 이미지 버전](#5-이미지-버전)
  - [6. 볼륨 경로](#6-볼륨-경로)
    - [choimory-dev](#choimory-dev)
    - [choimory-local 경로 변경](#choimory-local-경로-변경)
  - [남은 결정](#남은-결정-1)
- [추가3](#추가3)
- [추가3 확인](#추가3-확인)
  - [답변](#답변-3)
  - [추가3 반영](#추가3-반영)
  - [확인한 것과 주의할 점](#확인한-것과-주의할-점)
    - [DB 이름](#db-이름)
    - [이미지](#이미지)
    - [데이터 이전](#데이터-이전)
  - [최종 작업 계획](#최종-작업-계획)
    - [A. choimory-docker-compose 레포](#a-choimory-docker-compose-레포)
    - [B. choimory-dev-member-api (dev 브랜치)](#b-choimory-dev-member-api-dev-브랜치)
    - [C. choimory-dev-front (dev 브랜치)](#c-choimory-dev-front-dev-브랜치)
    - [D. 검증](#d-검증)
  - [확인 부탁](#확인-부탁)
- [docker compose down 정리 범위](#docker-compose-down-정리-범위)
  - [답변](#답변-4)
  - [docker compose down이 지우는 것](#docker-compose-down이-지우는-것)
  - [하나 주의할 점: profiles](#하나-주의할-점-profiles)
- [DB 이름과 컨테이너 이름](#db-이름과-컨테이너-이름)
  - [답변](#답변-5)
- [Flyway와 database 생성](#flyway와-database-생성)
  - [답변](#답변-6)
  - [Flyway가 하는 일과 못 하는 일](#flyway가-하는-일과-못-하는-일)
  - [database는 postgres 컨테이너가 만듦](#database는-postgres-컨테이너가-만듦)
  - [결정: DB 이름](#결정-db-이름)

---

# 개요

- 개인프로젝트 choimory-dev의 로컬 구동을 위한 docker compose 구성이 필요함
- compose 파일은 choimory-dev/ 하위에서 관리함
- 경로는 /Users/choimory/choimory_workspace/IdeaProjects/choimory-dev이며, 대상은 choimory-dev-front, choimory-dev-member-api (choimory-dev-sender-queue는 아직 미개발)

---

# plan1 확인

> plan1 확인

## 답변

plan1 개요를 확인하고, 대상 프로젝트(`choimory-dev-front`, `choimory-dev-member-api`)와 `choimory-dev-manifests`를 함께 살펴봄.

## 현재 상태

### choimory-dev-front

- Next.js 16 앱이고 기본 포트는 3000
- `APP_ENV`(local/dev/prod)에 따라 `env/.env.{APP_ENV}` 파일을 읽음 (git 제외)
- member-api 주소를 두 개 사용
  - `MEMBER_API_BASE_URL`: 서버(Route Handler)가 호출하는 주소
  - `NEXT_PUBLIC_MEMBER_API_BASE_URL`: 브라우저가 직접 호출하는 주소. 빌드할 때 번들에 고정됨

### choimory-dev-member-api

- Spring Boot 3.5.4-SNAPSHOT, Java 21, Gradle 멀티모듈(`member-api`, `member-domain`), 포트 8080
- 의존: PostgreSQL, Redis. 앱 기동 시 Flyway 마이그레이션 실행
- 환경변수로 받는 값: `rdb-host`, `rdb-port`, `rdb-database`, `rdb-user`, `rdb-password`, `redis-host`, `redis-port`, `redis-username`, `redis-password`, `jwt-secret`
- CORS(local 프로필)는 `http://localhost:3000`만 허용

### 공통

- 두 프로젝트 모두 **Dockerfile이 없음**
- `choimory-dev-manifests`(k8s)에 front, member-api, sender-queue의 `deployment.yaml`이 있지만 모두 빈 파일이라 참고할 이미지 정보가 없음

## 진행 계획 (안)

choimory-local과 같은 방식으로 서비스별 디렉토리를 두는 구성.

```
choimory-dev/
├── README.md
├── member-api/
│   ├── compose.yaml
│   └── .env.example
└── front/
    ├── compose.yaml
    └── .env.example
```

1. **Dockerfile 작성**: 각 앱 레포에 멀티스테이지 Dockerfile을 둠. 나중에 k8s 배포에도 같은 Dockerfile이 필요하므로 앱 레포에 두는 것을 추천
   - member-api: JDK 21로 `bootJar` 빌드 → JRE 21 이미지로 실행
   - front: Node로 `next build` → `output: "standalone"`으로 실행
2. **compose의 build context**: 상대경로 `../../../choimory-dev/choimory-dev-*`로 앱 레포를 직접 가리킴
3. **DB와 Redis**: choimory-local에서 상시 실행 중인 `postgres_choimory`, `redis_choimory`를 재사용
   - member-api는 `host.docker.internal:5432/6379`로 접속
   - 접속 정보는 `member-api/.env`로 주입
   - 필요하면 choimory-dev 전용 DB와 계정을 미리 생성
4. **front에서 member-api로 가는 연결**
   - 서버 쪽 호출: compose 네트워크 안의 `http://member-api:8080`
   - 브라우저 쪽 호출: `http://localhost:8080` (빌드 인자로 주입 필요)
5. **포트**: choimory-local과 같은 이유로 `127.0.0.1:3000`, `127.0.0.1:8080`에 바인딩

## 결정이 필요한 것

1. **compose를 쓰는 목적**
   - IDE로 개발할 때 한쪽(예: front)만 IDE로 띄우고 다른 쪽을 컨테이너로 띄우는 용도인지
   - 둘 다 컨테이너로 띄워서 통합 확인만 하는 용도인지
   - 이에 따라 포트 충돌 처리와 member-api 주소 설정이 달라짐
2. **Dockerfile 위치**: 각 앱 레포(추천) 또는 이 compose 레포. 앱 레포에 두면 작업 범위가 다른 레포까지 넓어짐
3. **DB**: choimory-local의 postgres/redis 재사용(추천) 또는 별도 기동. 재사용한다면 DB 이름과 계정
4. **compose 구조**: 위처럼 서비스별로 나눌지, `choimory-dev/compose.yaml` 하나에 front와 member-api를 묶을지
   - 둘이 서로 의존하므로 하나로 묶는 것도 자연스러움
   - sender-queue가 추가될 때는 service만 하나 더 넣으면 됨
5. **Spring 프로필**: `local` 또는 `dev`

---

# 추가1

- 프론트는 IDE로 구동하고 api는 컨테이너로 띄워서 개발시 활용하는 용도로도 쓸 수 있고, 프론트와 api를 모두 컨테이너로 띄워서 확인하는 용도로도 사용할 수 있음
- Dockerifle은 각 프로젝트 내에 작성
- DB는 별도로 올리자
- 컴포즈 구조는 전체 컴포즈 파일 하나, 서비스별 컴포즈 파일 각각 이렇게 다 놓는게 어때?
- 스프링 프로필 로컬

---

# 추가1 확인

> 추가1 확인

## 답변

추가1에서 결정한 내용(프론트 IDE + api 컨테이너 / 전체 컨테이너 두 용도, Dockerfile은 각 프로젝트 내, DB 별도 기동, 전체 + 서비스별 compose, 스프링 프로필 local)을 반영한 구성안.

## compose 구조: 전체 파일 + 서비스별 파일

Compose의 `include`(Compose v2.20 이상)를 사용.

```
choimory-dev/
├── compose.yaml              # 전체: member-api, front를 include
├── .env.example
├── postgres/compose.yaml
├── redis/compose.yaml
├── member-api/compose.yaml   # postgres, redis를 include
└── front/compose.yaml
```

- **api만 띄우고 front는 IDE로 개발**: `cd member-api && docker compose up -d` → postgres, redis, member-api 기동
- **전체를 컨테이너로 확인**: `cd choimory-dev && docker compose up -d` → front까지 기동

주의할 점

- **include는 겹치지 않게 구성**: 루트 compose가 postgres와 member-api(postgres 포함)를 둘 다 include하면 같은 서비스가 중복되어 에러가 남. 루트는 `member-api`, `front`만 include하고, DB는 member-api compose를 통해 들어오게 함
- **모든 파일에 `name: choimory-dev`를 동일하게 지정**: 프로젝트 이름이 다르면 api만 띄운 상태에서 전체로 전환할 때 `container_name`이 충돌함. 이름이 같으면 front만 추가로 붙음

대안: 파일 하나만 두고 `docker compose up -d member-api`를 실행하면 depends_on에 걸린 DB까지 같이 기동됨. 파일 수는 이쪽이 적지만, 요청한 대로 파일을 나누는 방식도 문제없이 가능함.

## 서비스별 구성

### postgres / redis (choimory-dev 전용)

- choimory-local이 이미 5432, 6379를 사용 중이므로 호스트 포트는 `127.0.0.1:15432`, `127.0.0.1:16379`로 다르게 잡음 (DataGrip 접속용)
- 컨테이너끼리는 `postgres:5432`, `redis:6379`로 통신
- postgres에 healthcheck를 넣고, member-api는 `depends_on: condition: service_healthy`로 대기. Flyway가 기동 시 DB가 준비되어 있어야 하기 때문
- DB와 계정은 `POSTGRES_DB`, `POSTGRES_USER`로 최초 기동 시 생성. redis는 choimory-local과 같은 ACL 방식

### member-api

- Dockerfile은 앱 레포에 두고, JDK 21로 `bootJar` 빌드 → JRE 21 이미지로 실행
- `SPRING_PROFILES_ACTIVE=local`로 실행
- 환경변수는 `RDB_HOST`, `REDIS_HOST`, `JWT_SECRET` 등 대문자+언더스코어로 주입. Spring이 `${rdb-host}` 같은 이름을 `RDB_HOST` 환경변수로 찾아주므로 앱 코드 수정 불필요
- 포트는 `127.0.0.1:8080`

### front

- Dockerfile은 앱 레포에 두고 `output: "standalone"`으로 빌드. 이를 위해 `next.config.ts` 한 줄 수정 필요
- 컨테이너에서는 `APP_ENV`를 주지 않고 환경변수를 직접 주입
  - `MEMBER_API_BASE_URL=http://member-api:8080`: 서버 쪽 호출용, 실행 시 주입
  - `NEXT_PUBLIC_MEMBER_API_BASE_URL=http://localhost:8080`: 브라우저용이라 빌드 인자로 주입
- `.dockerignore`에 `env/`, `.next`, `node_modules`를 넣어 로컬 env 파일이 이미지에 들어가지 않게 함
- CORS는 `localhost:3000`이 이미 허용되어 있어 두 경우 모두 그대로 동작
- 전체 컨테이너 모드에서는 IDE의 front를 꺼야 함 (둘 다 3000 포트 사용)

## 남은 결정

1. **볼륨 경로**: `~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/{postgres,redis}`로 할지
2. **이미지 버전**: choimory-local과 같은 `postgres:16.15-bookworm`, `redis:8.10.3`으로 맞출지. 새 DB이므로 postgres를 더 최신 메이저로 올리는 것도 가능
3. **restart 정책**: 개발할 때만 띄우는 용도라 `unless-stopped` 또는 정책 없음이 적합해 보임. choimory-local처럼 `always`가 필요한지
4. **DB 이름과 계정**: 예) DB `choimory_dev`, 계정 `choimory`. 비밀번호는 `.env.example`에 `changeme`로 둠
5. **작업 범위**: Dockerfile, `.dockerignore`, front의 `next.config.ts` 수정은 각 앱 레포에서 이뤄짐. 앱 레포 쪽도 이번 작업 히스토리에 같이 기록할지

---

# 추가2

- 하나의 컴포즈 파일만 만들고 `docker compose up -d {service-name}`으로 서비스별 구동 되는지 몰랐어. 그럼 그냥 파일 하나만 있어도 되지 않나? (근데 프론트만 제외하고 다 띄우려면 프론트 제외 api를 하나하나 다 명령어 쳐야하니까 힘든가?)
- db는 postgres_choimory-dev, redis_choimory-dev 이런식으로 (choimory는 개인용, choimory-dev는 choimory-dev 프로젝트용으로 구분하게)
- restart always 필요 없고, 오히려 껐을때 컨테이너랑 이미지가 날아가버리는 휘발성이면 더 편할듯?
- 프론트, 백엔드 리포에 도커파일도 적어줘야함
- 이미지 버전은 choimory-local과 맞춰서
- docker_volume 위치는 /Users/choimory/choimory_workspace/DataGripProjects/choimory-dev/docker_volume
  - 근데 추가로 해줘야하는게 choimory-local의 docker volume 위치를 `/Users/choimory/choimory_workspace/DataGripProjects/docker_volume`에서 `/Users/choimory/choimory_workspace/DataGripProjects/choimory/docker_volume`로 바꿨는데 이것도 좀 같이 맞춰주라

---

# 추가2 확인

> 추가2 확인

## 답변

추가2 내용을 항목별로 정리함.

## 1. compose 파일 하나 + profiles

파일 하나로 충분함. "프론트만 빼고 다 띄우기"는 `profiles`로 해결.

```yaml
services:
  postgres: ...
  redis: ...
  member-api: ...
  front:
    profiles: ["front"]   # 지정한 경우에만 기동
```

| 용도 | 명령어 | 뜨는 것 |
|---|---|---|
| front는 IDE로 개발 | `docker compose up -d` | postgres, redis, member-api |
| 전체를 컨테이너로 | `docker compose --profile front up -d` | 위 + front |

profile이 없는 서비스는 기본으로 모두 기동되므로, 나중에 sender-queue를 추가해도 명령어는 그대로임.

## 2. 컨테이너 이름

- `container_name`: `postgres_choimory-dev`, `redis_choimory-dev`, `member-api_choimory-dev`, `front_choimory-dev`
- compose 서비스 이름(컨테이너 간 통신 호스트명)은 `postgres`, `redis`, `member-api`, `front`

## 3. 휘발성 운용

- restart 정책은 넣지 않음
- 끌 때는 `docker compose down --rmi local` 사용

| 대상 | 결과 |
|---|---|
| 컨테이너, 네트워크 | 삭제 |
| 직접 빌드한 member-api, front 이미지 | 삭제 |
| 받아온 postgres, redis 이미지 | 남음 |

- postgres, redis 이미지는 남겨두는 게 다음 기동 시 빠름
- compose에는 "멈추면 자동 삭제" 옵션이 없으므로 `down`으로 운용. README에 명령어 정리
- DB 데이터는 bind mount라 down해도 남음. 경로를 지정했으므로 데이터는 유지하는 것으로 이해함. 매번 초기화를 원하면 볼륨을 빼면 됨

## 4. Dockerfile (앱 레포 작업)

| 레포 | 추가/수정 파일 |
|---|---|
| choimory-dev-member-api | `Dockerfile`, `.dockerignore` |
| choimory-dev-front | `Dockerfile`, `.dockerignore`, `next.config.ts`(`output: "standalone"`) 수정 |

- 각 레포에 AGENTS.md가 있으므로, 작업 시 해당 레포 규칙(히스토리 기록 등)도 따름

## 5. 이미지 버전

- choimory-local과 동일: `postgres:16.15-bookworm`, `redis:8.10.3`

## 6. 볼륨 경로

### choimory-dev

- `${HOME}/choimory_workspace/DataGripProjects/choimory-dev/docker_volume/{postgres,redis}`

### choimory-local 경로 변경

- 변경: `DataGripProjects/docker_volume` → `DataGripProjects/choimory/docker_volume`
- 수정 대상
  - `choimory-local/{postgres,redis,mysql,elasticsearch}/compose.yaml`의 volume 경로와 이전 안내 주석
  - `choimory-local/README.md`
  - 루트 `README.md`

주의할 점 (현재 상태 확인 결과)

- 새 경로(`choimory/docker_volume`)에 데이터가 복사되어 있음
- 하지만 실행 중인 `postgres_choimory`, `redis_choimory`, `elasticsearch_choimory`는 **아직 기존 경로**(`DataGripProjects/docker_volume`)를 마운트 중
- postgres가 계속 켜져 있었으므로, 실행 중에 복사했다면 복사본이 일관되지 않을 수 있음. 복사 이후 기존 경로에 쌓인 변경도 새 경로에는 없음

추천 순서

1. compose 경로 수정
2. `docker compose down`으로 기존 컨테이너 중지
3. 기존 경로 → 새 경로로 다시 복사 (`rsync -a --delete`)
4. `docker compose up -d`로 재기동 후 정상 기동 확인
5. 확인 후 기존 `DataGripProjects/docker_volume` 삭제

## 남은 결정

1. DB 데이터 유지 여부: 유지하는 것으로 이해했는데 맞는지
2. DB 이름과 계정: DB `choimory_dev`, 계정 `choimory`로 할지
3. 앱 레포 작업 방식: 각 레포의 브랜치와 커밋을 어떻게 할지(예: 각 레포 dev 브랜치), 히스토리를 각 레포에도 남길지
4. choimory-local 데이터 이전: 컨테이너 중지, 데이터 복사, 삭제를 직접 할지 Claude가 실행할지

---

# 추가3

- docker_volume 경로 
  - 니가 말한 경로가 더 이쁜거 같음
  - choimory-dev 도커 마운트 경로: `/Users/choimory/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/{postgres, redis..}`
  - choimory-local의 마운트 경로도 `/Users/choimory/choimory_workspace/DataGripProjects/docker_volume/choimory/{postgres, redis..}`로 변경해줘
- DB 데이터는 마운트 걸어서 유지할거임
- 이미지도 부팅 빠르게 유지하자
- db 계정명은 choimory로 
- 각 레포 현재 내가 dev로 해놨고 커밋은 내가 알아서 할거니까 파일만 작성해도 돼
- choimory-local 데이터 이전: compose만 수정해주면 내가 실행할거임. 일단 이전 데이터는 cp -r로 옮겨놨어

---

# 추가3 확인

> 추가3 확인

## 답변

추가3 내용을 반영해 최종 계획으로 정리함.

## 추가3 반영

| 항목 | 결정 |
|---|---|
| choimory-dev 볼륨 | `${HOME}/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/{postgres,redis}` |
| choimory-local 볼륨 | `${HOME}/choimory_workspace/DataGripProjects/docker_volume/choimory/{postgres,redis,elasticsearch,mysql}` |
| DB 데이터 | bind mount로 유지 |
| 이미지 | 받아온 postgres, redis 이미지는 유지. 끌 때 `docker compose down --rmi local` |
| DB 계정 | `choimory` |
| 앱 레포 | 현재 dev 브랜치에 파일만 작성. 커밋과 앱 레포 히스토리 기록은 하지 않음 |
| 데이터 이전 | compose만 수정. 실행은 사용자가 직접 함 |

## 확인한 것과 주의할 점

### DB 이름

- member-api README에 "서비스별로 PostgreSQL database를 따로 둔다"는 규칙이 있음
- 그래서 DB 이름은 프로젝트명보다 서비스 단위인 `member`를 제안. 나중에 sender-queue용 DB가 생기면 같은 postgres에 database만 추가

### 이미지

- "부팅 빠르게"를 받아온 이미지를 유지하라는 뜻으로 이해함
- 앱 이미지(member-api, front)는 `--rmi local`로 지워지지만, 빌드 캐시가 남아 다시 빌드할 때 빠름
- 앱 이미지까지 남기고 싶으면 그냥 `docker compose down`만 사용

### 데이터 이전

- 현재 상태
  - `docker_volume/choimory/`에 복사본이 있음
  - 실행 중인 `postgres_choimory` 등은 여전히 기존 경로 `docker_volume/{postgres,redis,elasticsearch}`를 마운트 중
  - 복사(20:41) 뒤에도 기존 elasticsearch 디렉토리가 수정됨(20:43). 실행 중에 복사한 셈이라 복사본이 어긋났을 수 있음
- 실행 시 추천 순서 (README에도 기록 예정)

```shell
cd choimory-local/<서비스> && docker compose down      # 기존 경로 컨테이너 중지
rsync -a --delete ~/choimory_workspace/DataGripProjects/docker_volume/<서비스>/ \
                  ~/choimory_workspace/DataGripProjects/docker_volume/choimory/<서비스>/
docker compose up -d                                   # 새 경로로 기동, 정상 확인
# 확인 후 기존 docker_volume/<서비스> 삭제
```

- 이전 단계에서 만든 것으로 보이는 빈 디렉토리 `DataGripProjects/choimory`, `DataGripProjects/choimory-dev`도 정리 가능

## 최종 작업 계획

### A. choimory-docker-compose 레포

1. `choimory-local/{postgres,redis,mysql,elasticsearch}/compose.yaml`: 볼륨 경로와 이전 안내 주석 수정
2. `choimory-dev/compose.yaml` 하나 작성
   - 서비스: postgres, redis, member-api, front(`profiles: ["front"]`)
   - 컨테이너 이름: `*_choimory-dev`
   - 포트: `127.0.0.1` 바인딩. postgres 15432, redis 16379, api 8080, front 3000
   - postgres healthcheck를 넣고 member-api는 `service_healthy` 대기
   - restart 정책 없음
3. `choimory-dev/.env.example` 작성
   - 항목: POSTGRES 계정과 DB, REDIS 계정, JWT_SECRET
   - 비밀번호는 `changeme`
4. 문서 수정
   - `choimory-dev/README.md`: 사용법, 두 가지 실행 모드, down 명령어
   - `choimory-local/README.md`, 루트 `README.md`: 경로와 구성 반영

### B. choimory-dev-member-api (dev 브랜치)

5. `Dockerfile`: gradle 빌드 → JRE 21 실행으로 나눈 멀티스테이지
6. `.dockerignore`

### C. choimory-dev-front (dev 브랜치)

7. `Dockerfile`: 멀티스테이지 standalone. `NEXT_PUBLIC_MEMBER_API_BASE_URL`은 빌드 인자로 받음
8. `.dockerignore`: `env/`, `.next`, `node_modules` 제외
9. `next.config.ts`: `output: "standalone"` 추가

### D. 검증

- `docker compose config`로 문법 확인
- 실제 빌드와 기동(`docker compose up -d --build`)까지 할지 확인 필요. choimory-local 컨테이너와 포트가 겹치지 않아 같이 띄워도 됨

## 확인 부탁

1. DB 이름을 `member`로 해도 되는지
2. D의 실제 빌드와 기동 테스트를 Claude가 실행해도 되는지

두 가지에 답을 받으면 plan1에 기록하고 시작함. 시작할 때는 calendar를 TASK로 바꾸고 task1에 기록하며 진행.

---

# docker compose down 정리 범위

> 아 휘발되는것도 그냥 docker compose down하면 알아서 정리돼? rmi 옵션 붙이면 이미지까지 정리되고? 그냥 도커 컴포즈 명령어로 지원되는거임?

## 답변

별도 스크립트 없이 `docker compose down` 명령어와 옵션만으로 정리됨.

## docker compose down이 지우는 것

| 대상 | `down` | `down -v` | `down --rmi local` | `down --rmi all` |
|---|---|---|---|---|
| 컨테이너 | 삭제 | 삭제 | 삭제 | 삭제 |
| compose가 만든 네트워크 | 삭제 | 삭제 | 삭제 | 삭제 |
| named/익명 볼륨 | 유지 | **삭제** | 유지 | 유지 |
| bind mount 데이터 (호스트 경로) | 유지 | 유지 | 유지 | 유지 |
| 직접 빌드한 이미지 (member-api, front) | 유지 | 유지 | **삭제** | **삭제** |
| 받아온 이미지 (postgres, redis) | 유지 | 유지 | 유지 | **삭제** |
| 빌드 캐시 | 유지 | 유지 | 유지 | 유지 |

- `down`은 `up`이 만든 컨테이너와 네트워크를 지움. 다음 `up` 때 새로 생성
- 컨테이너만 멈추고 남기려면 `docker compose stop` 사용
- `--rmi local`은 compose 파일에 `image:` 이름이 없는 이미지, 즉 `build:`로 만든 이미지만 지움
  - 그래서 member-api와 front에는 `image:` 이름을 붙이지 않을 계획. 이름을 붙이면 local 대상에서 빠짐
  - 받아온 postgres, redis 이미지는 남아서 다음 기동이 빠름
- DB 데이터는 bind mount라 `-v`를 붙여도 지워지지 않음
- 빌드 캐시는 남으므로 재빌드가 빠름. 쌓이면 가끔 `docker builder prune`으로 정리

## 하나 주의할 점: profiles

front는 `profiles: ["front"]`로 둘 계획. profile을 지정하지 않은 `down`이 front 컨테이너까지 확실히 지우게 하려면 profile을 같이 주는 게 안전함.

```shell
docker compose --profile front down --rmi local
```

front를 띄우지 않았을 때도 이 명령어를 써도 문제없음. README에는 이 명령어 하나로 정리.

---

# DB 이름과 컨테이너 이름

> db이름이 컨테이너이름 말하는거야?

## 답변

서로 다른 것임.

| 구분 | 값(안) | 의미 |
|---|---|---|
| 컨테이너 이름 | `postgres_choimory-dev` | Docker 컨테이너의 이름. `docker ps`에 보이는 이름 |
| DB 이름 | `member` | 그 postgres 서버 안에 만드는 database. `CREATE DATABASE member`에 해당 |
| DB 계정 | `choimory` | postgres에 접속하는 사용자 |

- postgres 컨테이너 하나 안에 database를 여러 개 만들 수 있음
- member-api는 `jdbc:postgresql://postgres:5432/member`처럼 그중 하나에 접속. 이 값이 앱의 `rdb-database` 환경변수로 들어감
- DataGrip에서는 `localhost:15432`, database `member`, 계정 `choimory`로 접속
- `member`로 제안한 이유: member-api README에 "서비스별로 PostgreSQL database를 따로 둔다"는 규칙이 있음. 나중에 sender-queue가 DB를 쓰면 같은 컨테이너 안에 database를 하나 더 만드는 식

---

# Flyway와 database 생성

> member-api안에 flyway 있는데 알아서 만들어지지 않음?

## 답변

테이블은 Flyway가 만들지만, database 자체는 만들지 않음.

## Flyway가 하는 일과 못 하는 일

- member-api의 Flyway는 앱 기동 시 `docs/flyway/v1/` 아래 V1~V3(스키마 생성, timestamptz 변환, 권한 초기 데이터)를 실행
- Flyway는 접속 주소(`jdbc:postgresql://postgres:5432/<DB 이름>`)로 **이미 접속한 database 안에서** 동작
- database가 없으면 접속부터 실패(`database "..." does not exist`)하므로 Flyway가 실행될 기회도 없음
- 마이그레이션 SQL에도 `CREATE DATABASE`는 없음

## database는 postgres 컨테이너가 만듦

postgres 공식 이미지는 데이터 디렉토리가 비어 있을 때(최초 기동) 환경변수로 database를 생성함.

```yaml
environment:
  POSTGRES_USER: choimory
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  POSTGRES_DB: choimory_dev_member   # 최초 기동 시 이 database를 생성
```

1. **postgres 최초 기동**: `choimory` 계정과 database 생성
2. **member-api 기동**: 해당 database에 접속, Flyway가 테이블과 초기 데이터 생성
3. **다음 기동부터**: bind mount에 데이터가 남아 있으므로 Flyway는 이미 적용된 버전을 건너뜀

DB 이름은 compose에 한 번만 정해두면 되고, 따로 손으로 만들 필요는 없음.

## 결정: DB 이름

- postgres DB 이름은 `choimory_dev_member`로 결정 (앞서 제안한 `member` 대신 사용)
- member-api 접속 주소: `jdbc:postgresql://postgres:5432/choimory_dev_member`
- DataGrip 접속: `localhost:15432`, database `choimory_dev_member`, 계정 `choimory`
