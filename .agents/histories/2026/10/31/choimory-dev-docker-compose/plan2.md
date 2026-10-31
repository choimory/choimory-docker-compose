# 목차

- [개요](#개요)
- [down 후 front가 남는 문제](#down-후-front가-남는-문제)
  - [답변](#답변)
  - [원인](#원인)
  - [지금 정리하기](#지금-정리하기)
  - [앞으로](#앞으로)
- [--profile 용도](#--profile-용도)
  - [답변](#답변-1)
  - [동작 방식](#동작-방식)
  - [모든 명령에 똑같이 적용됨](#모든-명령에-똑같이-적용됨)
  - [왜 썼나](#왜-썼나)
- [up의 --build 유무 차이](#up의---build-유무-차이)
  - [답변](#답변-2)
  - [차이](#차이)
  - [다시 빌드해도 빠른 이유](#다시-빌드해도-빠른-이유)
  - [우리 구성에서는](#우리-구성에서는)
  - [관련 명령](#관련-명령)
- [--build, --rmi local 정리와 이미지 유지](#--build---rmi-local-정리와-이미지-유지)
  - [답변](#답변-3)
  - [명령 정리](#명령-정리)
  - [이미지를 남길 때 기억할 점](#이미지를-남길-때-기억할-점)
  - [README, compose 반영](#readme-compose-반영)
- [추가1](#추가1)
- [plan2 추가1 확인](#plan2-추가1-확인)
  - [답변](#답변-4)
  - [먼저 알아야 할 제약: profile은 더하기만 됨](#먼저-알아야-할-제약-profile은-더하기만-됨)
  - [구성안](#구성안)
  - [확인할 점](#확인할-점)
    - [no-{서비스}는 --scale 추천](#no-서비스는---scale-추천)
    - [front-only 정의](#front-only-정의)
    - [front에서 member-api로 가는 주소](#front에서-member-api로-가는-주소)
    - [그 밖의 수정](#그-밖의-수정)
  - [확인 방법과 결과](#확인-방법과-결과)
  - [정해야 할 것](#정해야-할-것)
- [추가2](#추가2)
- [추가2 확인](#추가2-확인)
  - [답변](#답변-5)
  - [COMPOSE_PROFILES가 뭔지](#compose_profiles가-뭔지)
  - [front-only를 프론트만 띄울 때의 동작](#front-only를-프론트만-띄울-때의-동작)
  - [최종 구성](#최종-구성)
  - [작업 계획](#작업-계획)

---

# 개요

- task1에서 작성한 choimory-dev compose를 사용자가 직접 실행해 봄
- `up`은 정상 동작했으나, `docker compose down` 후 front 컨테이너가 남는 현상이 있었음
- 원인인 compose profiles 동작을 정리함

---

# down 후 front가 남는 문제

> up은 확인했는데 down해도 front는 안내려가는중
>
> ```shell
> ╰─$ docker compose down                                                 1 ↵
> [+] Running 4/4
>  ✔ Container member-api_choimory-dev  Removed                          0.3s
>  ✔ Container redis_choimory-dev       Removed                          0.2s
>  ✔ Container postgres_choimory-dev    Removed                          0.2s
>  ! Network choimory-dev_default       Resource is still in use         0.0s
> ╰─$ docker ps -a
> CONTAINER ID   IMAGE                     COMMAND                   CREATED              STATUS              PORTS                      NAMES
> 7bb945f93ebe   choimory-dev-front        "docker-entrypoint.s…"   About a minute ago   Up About a minute   127.0.0.1:3000->3000/tcp   front_choimory-dev
> dee407330b7f   redis:8.10.3              "docker-entrypoint.s…"   14 minutes ago       Up 14 minutes       127.0.0.1:6379->6379/tcp   redis_choimory
> e8244d6c0ca8   postgres:16.15-bookworm   "docker-entrypoint.s…"   14 minutes ago       Up 14 minutes       127.0.0.1:5432->5432/tcp   postgres_choimory
> dbddfcca3714   elasticsearch:8.19.23     "/bin/tini -- /usr/l…"   15 minutes ago       Up 14 minutes       127.0.0.1:9200->9200/tcp   elasticsearch_choimory
> ```

## 답변

profile 없이 `docker compose down`을 실행해서 생긴 현상.

## 원인

- front는 `profiles: ["front"]`에 속해 있어서, profile을 지정하지 않은 명령에서는 compose가 없는 서비스로 취급함
- 그래서 `down`이 member-api, redis, postgres만 지우고 front는 건드리지 않음
- front가 아직 네트워크를 쓰고 있어서 `Network ... Resource is still in use`도 함께 발생
- `up`도 같은 규칙이므로, front를 띄울 때 `--profile front`를 붙였듯이 끌 때도 붙여야 함

## 지금 정리하기

```bash
docker compose --profile front down --rmi local
```

- front 컨테이너, 남은 네트워크, 빌드한 이미지가 모두 정리됨
- 이번 `down`에 `--rmi local`이 빠져 남아 있던 member-api 이미지도 같이 지워짐

## 앞으로

- 어떤 모드로 띄웠든 끌 때는 항상 `docker compose --profile front down --rmi local` 하나만 사용
- 번거로우면 셸 alias 등록. 예: `alias cdd-down='docker compose --profile front down --rmi local'`
- README에는 현재 "front를 띄우지 않았어도 종료는 `--profile front`를 붙인 명령으로 한다" 정도로만 적혀 있음. 필요하면 "그냥 `down`을 하면 front가 남는다"는 경고를 README와 compose 상단 주석에 더 눈에 띄게 추가

---

# --profile 용도

> --profile은 무슨 용도야?

## 답변

`--profile`은 compose 파일 안의 서비스 중 **어떤 것을 이번 명령에 포함할지 고르는 스위치**.

## 동작 방식

| 서비스 | 우리 compose | 언제 대상이 되나 |
|---|---|---|
| `profiles:`가 없는 서비스 | postgres, redis, member-api | 항상 |
| `profiles:`가 있는 서비스 | front (`profiles: ["front"]`) | 해당 profile을 켰을 때만 |

```bash
docker compose up -d                    # profile 없음 → postgres, redis, member-api
docker compose --profile front up -d    # front profile 켬 → 위 + front
```

## 모든 명령에 똑같이 적용됨

`up`에만 해당하는 옵션이 아니라 compose 명령 전체에 걸리는 필터. `down`, `ps`, `logs`, `build` 모두 같은 규칙을 따름.

```bash
docker compose ps                     # front가 떠 있어도 목록에 안 보임
docker compose --profile front ps     # front까지 보임
docker compose down                   # front는 대상이 아님 → down 후 front가 남은 원인
docker compose --profile front down   # front까지 정리
```

profile을 켜지 않은 명령에서 front는 "이 compose에 없는 서비스"처럼 취급됨.

## 왜 썼나

"front는 IDE로 개발하고 나머지만 컨테이너로" 띄우는 게 기본 용도라서, front만 옵션으로 빼기 위해 사용함.

- **profile을 안 썼다면**: `docker compose up -d postgres redis member-api`처럼 서비스를 하나하나 적어야 함. sender-queue가 생기면 명령도 같이 길어짐
- **profile을 쓰면**: 기본 명령은 `up -d` 하나로 유지되고, front가 필요할 때만 `--profile front`를 붙임
- profile은 여러 개 만들어 조합할 수도 있음 (예: `--profile front --profile monitoring`). 지금은 front 하나만 있음

---

# up의 --build 유무 차이

> docker compose up에 --build 유무 차이는 뭐야?

## 답변

`--build`는 **앱 이미지를 이번에 다시 빌드할지**를 정하는 옵션. `build:`가 있는 member-api, front에만 해당하고, `image:`만 있는 postgres, redis는 받아온 이미지를 쓰므로 상관없음.

## 차이

| 상황 | `docker compose up -d` | `docker compose up -d --build` |
|---|---|---|
| 앱 이미지가 없음 | 자동으로 빌드 | 빌드 |
| 앱 이미지가 이미 있음 | **있는 이미지를 그대로 씀** (빌드 안 함) | 다시 빌드 |
| 코드를 고친 뒤 | **고친 코드가 반영 안 됨** | 반영됨 |

- `--build` 없이 `up`하면 compose는 `choimory-dev-member-api` 같은 이미지가 있는지만 확인함. 있으면 그 이미지로 띄우고, 소스가 바뀌었는지는 확인하지 않음
- `--build`를 주면 `up` 전에 `docker compose build`를 먼저 실행함. 만들어진 이미지가 기존과 다르면 컨테이너를 새로 만들어 교체

## 다시 빌드해도 빠른 이유

- **소스가 그대로일 때**: Docker 레이어 캐시를 그대로 써서 몇 초 안에 끝남. 이미지도 같으니 컨테이너도 바꾸지 않음
- **소스가 바뀌었을 때**: 바뀐 레이어부터만 다시 빌드함
  - member-api: Gradle 의존성을 캐시 마운트에서 재사용
  - front: `package.json`이 그대로면 `npm ci` 레이어 재사용

## 우리 구성에서는

- 평소 종료 명령이 `down --rmi local`이라 앱 이미지가 매번 지워지므로, 다음 `up`은 `--build`가 없어도 빌드하게 됨
- 하지만 `--rmi local` 없이 `down`했거나 `stop`만 했다면 예전 이미지가 남아 있음. 이때 `--build`가 없으면 **예전 코드로 뜸**
- 그래서 README에는 항상 `--build`를 붙이는 명령으로 적어 둠. 바뀐 게 없으면 캐시 덕분에 거의 비용이 없고, 오래된 이미지로 뜨는 실수를 막아줌

## 관련 명령

```bash
docker compose build                 # 빌드만 하고 띄우지는 않음
docker compose build --no-cache      # 캐시 없이 처음부터 빌드 (캐시가 꼬였다고 의심될 때)
docker compose up -d --build member-api   # member-api만 다시 빌드해서 교체
```

---

# --build, --rmi local 정리와 이미지 유지

> 쉽게말해서 코드 바뀐게 있어서 이미지 새로 빌드해야할때 --build쓰는거고, down시 이미지도 지우고 싶으면 --rmi하는거지? 근데 이미지는 그냥 안지워도 될거같네 어차피 다시 올릴때 해당 이미지 사용할거고 --build할땐 덮어쓸거니까 latest로

## 답변

맞음. 앱 이미지는 지우지 않는 것을 기본으로 하고, README와 compose 주석에 이 기준으로 반영함.

## 명령 정리

| 상황 | 명령 |
|---|---|
| 평소 기동 | `docker compose up -d` (남아 있는 이미지 그대로 사용) |
| 코드가 바뀌었을 때 | `docker compose up -d --build` (`latest`로 덮어쓰고 컨테이너 교체) |
| 평소 종료 | `docker compose --profile front down` (이미지는 유지) |
| 이미지까지 지우고 싶을 때 | `docker compose --profile front down --rmi local` |

## 이미지를 남길 때 기억할 점

- **`--build`를 깜빡하면 예전 코드로 뜸**: 이미지가 남아 있으면 compose는 소스가 바뀌었는지 확인하지 않음. 헷갈리면 항상 `--build`를 붙여도 됨. 바뀐 게 없으면 캐시로 몇 초 안에 끝남
- **덮어쓴 이전 이미지는 `<none>`으로 남음**: `latest` 태그는 새 이미지로 옮겨가지만, 예전 이미지 자체는 이름 없이 디스크에 남음. 가끔 `docker image prune`으로 정리

## README, compose 반영

- `choimory-dev/README.md`, 루트 `README.md`의 choimory-dev 실행 방법
  - 기동/종료 명령을 기본 명령과 `--build`, `--rmi local` 붙인 명령으로 나눠 정리
  - `--build`, `--rmi local`을 언제 쓰고 어떻게 동작하는지 표 추가
  - 주의사항 추가: `--build`를 빼면 예전 코드로 뜸, 이미지가 없으면 자동 빌드, 덮어쓴 이전 이미지는 `<none>`으로 남음
  - 개요와 profiles 섹션의 "끌 때 이미지를 지운다", "종료는 `--rmi local`" 문구를 새 기본에 맞게 수정
- `choimory-dev/compose.yaml` 상단 주석: 실행 명령 안내를 같은 기준으로 변경하고, "profile 없이 down하면 front가 남는다"는 주의 추가

---

# 추가1

- 프로필을 좀 다듬을까 함
  - all 혹은 프로필 미지정: 전체
  - front-only: 프론트만 실행 (백엔드 개발시 활용)
  - back-only: 백엔드만 실행 (프론트 개발시 활용)
  - db-only: db만 실행 (백엔드 IDE로 개발할때 DB만 띄우기 용도)
  - no-{특정서비스}: 해당서비스만 제외하고 실행 (이를테면 백엔드의 member-api, sender-queue 중에 내가 member-api만 현재 IDE로 개발중이라 이걸 확인하고 싶으면 나머지는 컨테이너로 올리고, member-api는 IDE로 구동하는거임)
- 내 예상 패턴 아마 이럴거 같음
  - IDE로 백엔드 로컬 개발할때: 일단 db만 컴포즈로 올려서 백엔드 개발 들어감
  - IDE로 프론트 로컬 개발할때: 백엔드와 db 전체 컴포즈로 올려서 프론트 개발 들어감
  - 백엔드 개발 확인시: 개발하던 특정 백엔드는 로컬 구동하고, 나머지는 컴포즈로 올려서 테스트함
  - 프론트 개발 확인시: 개발하던 특정 프론트는 로컬 구동하고, 나머지는 컴포즈로 올려서 테스트함

---

# plan2 추가1 확인

> plan2 추가1 확인

## 답변

구상한 4가지 패턴은 compose로 모두 구현 가능. 다만 profiles의 동작 방식 때문에 구현 방법을 조금 바꿔야 해서, 임시 compose 파일로 직접 확인한 결과와 함께 정리함.

## 먼저 알아야 할 제약: profile은 더하기만 됨

- `profiles:`가 없는 서비스는 **어떤 profile을 줘도 항상 뜸**
- 지금처럼 postgres, redis, member-api에 profile이 없으면, `db-only`를 줘도 member-api가 같이 떠서 "DB만"이 안 됨
- 그래서 **모든 서비스에 profile을 달아야 함**
- 그러면 profile 미지정 시 아무것도 안 뜨므로, `.env`에 기본 profile을 넣어 해결

```bash
# .env
COMPOSE_PROFILES=all   # profile 미지정 시 all로 동작
```

- `--profile db-only`처럼 명령에 직접 주면 `.env` 값보다 우선함 (확인함)
- **덤으로 down 문제도 해결됨**: 그냥 `docker compose down`이 기본 `all`로 동작해서, 어떤 모드로 띄웠든 전부 내려감 (확인함)

## 구성안

| 서비스 | profiles |
|---|---|
| postgres, redis | `all`, `db-only`, `back-only` |
| member-api (나중에 sender-queue도) | `all`, `back-only` |
| front | `all` |

| 패턴 | 명령 | 뜨는 것 |
|---|---|---|
| 전체 | `docker compose up -d` | 전부 |
| 백엔드를 IDE로 개발 | `docker compose --profile db-only up -d` | postgres, redis |
| 프론트를 IDE로 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` | DB + 백엔드 전체 |
| 특정 백엔드만 IDE, 나머지는 컨테이너 | `docker compose up -d --scale member-api=0` | member-api만 빼고 전부 |
| 종료 (모든 경우) | `docker compose down` | 전부 정리 |

## 확인할 점

### no-{서비스}는 --scale 추천

- profile로 만들면 `no-member-api`, `no-sender-queue`, `no-front`… 를 다른 모든 서비스에 하나하나 달아야 함. 서비스가 늘수록 관리가 복잡해짐
- `--scale member-api=0`은 compose 기본 기능이라 설정 없이 어떤 서비스에나 바로 사용 가능
- 여러 개를 빼려면 `--scale member-api=0 --scale front=0`처럼 이어 씀. `container_name`이 있어도 0으로는 잘 동작함 (확인함)
- profile 이름으로 맞추는 쪽을 원하면 그렇게도 가능

### front-only 정의

- 백엔드를 IDE로 개발할 때도 DB는 필요하므로, "front만" 띄우면 IDE 백엔드가 붙을 DB가 없음
- 실제로 필요한 건 "DB + front"(백엔드 전부 IDE)일 것으로 보임. 지금은 백엔드가 member-api 하나뿐이라 `--scale member-api=0`과 같음
- 그래서 빼는 것을 제안. 필요하면 "DB + front"로 정의해 추가

### front에서 member-api로 가는 주소

- 지금 front 서버는 `http://member-api:8080`(컨테이너 이름)으로 호출함. member-api를 IDE로 돌리면 이 주소로는 닿지 않음
- `http://host.docker.internal:8080`으로 바꾸면 member-api가 컨테이너든 IDE든 호스트의 8080을 거쳐 붙음 (컨테이너에서 호스트 포트로 접속되는 것 확인함)
- 브라우저는 원래 `localhost:8080`이라 영향 없음
- 나중에 sender-queue가 member-api를 부를 때도 같은 방식 사용

### 그 밖의 수정

- front의 `depends_on: member-api`에 `required: false` 추가. member-api를 뺐을 때도 front가 뜨게 하기 위함 (동작 확인함)
- IDE로 백엔드를 돌릴 때는 IDE 실행 설정의 DB/Redis 주소를 choimory-dev 쪽으로 맞춰야 함
  - DB: `localhost:15432`, `choimory_dev_member`
  - Redis: `localhost:16379`
  - choimory-local의 5432, 6379가 아님에 주의

## 확인 방법과 결과

scratchpad에 db, api, front 3개 서비스(alpine 이미지)로 임시 compose를 만들어 확인함.

| 확인 항목 | 결과 |
|---|---|
| `.env`의 `COMPOSE_PROFILES=all`, profile 미지정 | db, api, front 모두 대상 |
| `--profile db-only` | db만 대상 (`.env` 값보다 우선) |
| `--profile no-api` + front의 `depends_on: api`에 `required: false` | api 없이 db, front 기동 |
| profile 없이 `docker compose down` | 위에서 띄운 front까지 모두 삭제 |
| `up -d --scale api=0` | api만 빼고 기동, `container_name`이 있어도 문제없음 |
| 컨테이너에서 `host.docker.internal:5432` | 호스트에 바인딩된 choimory-local postgres에 접속됨 |

- 확인용 컨테이너는 모두 정리함. 확인 중 받은 `alpine:3.20` 이미지만 남아 있음 (필요 없으면 `docker rmi alpine:3.20`)

## 정해야 할 것

1. `no-{서비스}`: `--scale`(추천) 또는 profile
2. `front-only`: 빼기(추천) 또는 "DB + front"로 추가
3. `COMPOSE_PROFILES=all`을 `.env`에 두는 방식 (`.env.example`과 현재 사용 중인 `.env` 모두에 추가)

---

# 추가2

1. no-{service} 대신 --scale 서비스=0 사용하자. 대신 readme에 해당 명령어도 잘 적어줘
2. front-only는 프론트만 띄우는게 맞음. 왜냐면 front-only를 쓴다는거는, 백엔드는 내가 IDE로 개발중이라는 얘기고, 그럼 즉 db도 내가 별도로 db-only로 띄워놓고 작업할테니까
3. 프론트에서 api로 가는 주소는 지금 얘기해준대로 컨테이너로 실행중이던 IDE로 실행중이던 모두 닿게 해줘
4. COMPOSE_PROFILE은 뭔지 내가 이해 못했어. 명령어 --profile 말고 .env에 프로필 적어서 docker compose up -d로도 가능하게 하려는 거야? 

---

# 추가2 확인

> 추가2 확인

## 답변

추가2의 1~3번(`--scale` 사용, front-only는 프론트만, front → member-api 주소는 컨테이너/IDE 모두 닿게)은 그대로 반영하고, 4번(`COMPOSE_PROFILES`)을 설명함.

## COMPOSE_PROFILES가 뭔지

`COMPOSE_PROFILES`는 **`--profile`을 환경변수로 주는 방법**.

- compose는 실행할 때 같은 디렉토리의 `.env`를 자동으로 읽음
- 그래서 `.env`에 `COMPOSE_PROFILES=all`이 있으면 `docker compose up -d`가 `docker compose --profile all up -d`와 똑같이 동작함

이번 구조에서 모든 서비스에 profile을 달기 때문에 필요함.

| | `.env`에 `COMPOSE_PROFILES=all` 없음 | 있음 |
|---|---|---|
| `docker compose up -d` | **아무것도 안 뜸** (모든 서비스에 profile이 있어서) | 전체 기동 |
| `docker compose down` | **아무것도 안 내려감** | 전체 정리 |
| `docker compose --profile db-only up -d` | DB만 | DB만 (명령의 `--profile`이 `.env`보다 우선) |

- "profile 미지정 = 전체", "그냥 `down` = 전체 정리"를 만들기 위한 기본값
- `.env` 값을 `db-only` 등으로 바꿔 내 기본 모드를 다르게 둘 수도 있음

## front-only를 프론트만 띄울 때의 동작

- `db-only`를 먼저 띄운 상태에서 따로 `--profile front-only up -d`를 해도 DB는 그대로 유지됨 (임시 compose로 확인함. db, front가 함께 실행 중)
- 한 줄로 같이 띄울 수도 있음

```bash
docker compose --profile db-only --profile front-only up -d
```

## 최종 구성

| 서비스 | profiles |
|---|---|
| postgres, redis | `all`, `db-only`, `back-only` |
| member-api (나중에 sender-queue도) | `all`, `back-only` |
| front | `all`, `front-only` |

| 패턴 | 명령 |
|---|---|
| 전체 | `docker compose up -d` |
| 백엔드 IDE 개발 | `docker compose --profile db-only up -d` |
| 프론트 IDE 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` |
| 백엔드 전부 IDE + 프론트 컨테이너 | `docker compose --profile db-only --profile front-only up -d` |
| 특정 서비스만 빼기 | `docker compose up -d --scale member-api=0` (여러 개는 `--scale A=0 --scale B=0`) |
| 코드가 바뀌었을 때 | 위 명령에 `--build` |
| 종료 (모든 경우) | `docker compose down` |

## 작업 계획

1. **`choimory-dev/compose.yaml`**
   - 모든 서비스에 위 profiles 적용
   - front의 `MEMBER_API_BASE_URL`을 `http://host.docker.internal:8080`으로 변경 (member-api가 컨테이너든 IDE든 닿게)
   - front의 `depends_on: member-api`에 `required: false` 추가
   - 상단 주석의 실행 안내를 새 구성에 맞게 수정
2. **`.env.example`, 현재 사용 중인 `.env`**: `COMPOSE_PROFILES=all` 추가
3. **README** (`choimory-dev/README.md`, 루트 `README.md`)
   - profiles 섹션, 패턴별 명령, `--scale` 사용법 정리
   - IDE로 백엔드를 돌릴 때 붙을 주소 명시 (DB `localhost:15432`, Redis `localhost:16379`)
   - "`--profile front` + `--rmi local`" 기준으로 적힌 기존 내용을 새 기준으로 변경
4. **테스트**
   - profile별 대상 서비스를 `config`로 확인
   - 전체 기동 후 front 서버를 거친 로그인으로 `host.docker.internal` 경로 동작 확인
   - `--scale member-api=0` 확인
   - 끝나면 `down`으로 정리

- 앱 레포는 수정 없음. `MEMBER_API_BASE_URL`은 실행 시 주입하는 값이라 front 이미지를 다시 빌드할 필요 없음
