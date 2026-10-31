# 목차

- [개요](#개요)
- [앱 레포 경로와 docker compose up](#앱-레포-경로와-docker-compose-up)
  - [답변](#답변)
  - [경로 기준](#경로-기준)
  - [경로가 없을 때 어떻게 되나](#경로가-없을-때-어떻게-되나)
  - [실제로 신경 쓸 상황](#실제로-신경-쓸-상황)
  - [확인 방법](#확인-방법)
- [build.context를 GitHub 주소로](#buildcontext를-github-주소로)
  - [답변](#답변-1)
  - [방법](#방법)
  - [말씀하신 단점 외에 걸리는 점](#말씀하신-단점-외에-걸리는-점)
  - [참고: 레포 이름](#참고-레포-이름)
  - [보통은 이렇게 씀](#보통은-이렇게-씀)
- [build context를 .env로 빼기](#build-context를-env로-빼기)
  - [답변](#답변-2)
  - [변경 계획](#변경-계획)
  - [정해야 할 것](#정해야-할-것)
- [compose 기본값 제거, .env.example에 값 넣기](#compose-기본값-제거-envexample에-값-넣기)
  - [답변](#답변-3)
  - [변수가 없을 때 동작 비교](#변수가-없을-때-동작-비교)
  - [작업 계획](#작업-계획)
- [:? 방식](#-방식)
  - [답변](#답변-4)
  - [compose 변수 표기 정리](#compose-변수-표기-정리)
  - [우리 compose에 적용하면](#우리-compose에-적용하면)
  - [왜 이걸 추천했나](#왜-이걸-추천했나)
- [db-only에서 postgres credential 오류](#db-only에서-postgres-credential-오류)
  - [답변](#답변-5)
  - [원인](#원인)
  - [해결 방법](#해결-방법)
- [이미지 삭제나 --build로 해결되는지](#이미지-삭제나---build로-해결되는지)
  - [답변](#답변-6)
  - [이유](#이유)
  - [해결은 두 가지](#해결은-두-가지)

---

# 개요

- task2에서 profiles 재구성을 마친 뒤, choimory-dev compose가 앱 레포 위치에 얼마나 의존하는지 확인함
- compose의 `build.context`가 상대경로로 앱 레포를 가리키므로, 경로가 없을 때의 동작을 경우별로 정리함

---

# 앱 레포 경로와 docker compose up

> 궁금한게 docker compose up 하려면 정확한 경로에 프로젝트들이 (dockerfile이) 있어야 하는거임?

## 답변

**이미지를 빌드할 때만** 정확한 경로가 필요함.

## 경로 기준

```yaml
member-api:
  build:
    context: ../../../choimory-dev/choimory-dev-member-api
```

- 이 상대경로는 **터미널 위치가 아니라 `compose.yaml` 파일 위치 기준**
- `choimory-docker-compose/choimory-dev/`에서 세 단계 올라간 `IdeaProjects/`가 기준이 됨
- 실제 위치는 `IdeaProjects/choimory-dev/choimory-dev-member-api`이고, 이 폴더에 `Dockerfile`이 있어야 함 (front도 같은 방식)

## 경로가 없을 때 어떻게 되나

| 상황 | 결과 |
|---|---|
| 앱 이미지가 이미 있음 + `up -d` | **경로가 없어도 뜸** (있는 이미지 사용) |
| 앱 이미지가 이미 있음 + `up -d --build` | 실패 (`unable to prepare context: path ... not found`) |
| 앱 이미지가 없음 (처음, `--rmi local` 후) | 빌드가 필요해서 실패 |
| `--profile db-only` (postgres, redis만) | **경로와 상관없이 뜸** (받아온 이미지만 씀) |

- 경로는 **빌드할 때만** 확인함
- 이미지가 남아 있으면 앱 레포가 없어도 `up` 가능
- DB만 띄우는 `db-only`는 앱 레포가 전혀 필요 없음

## 실제로 신경 쓸 상황

- **다른 맥이나 새 환경**: 앱 레포를 같은 상대 위치에 clone해야 빌드됨. `choimory-docker-compose`와 `choimory-dev`가 같은 `IdeaProjects/` 아래 있어야 함
- **레포를 다른 곳으로 옮길 때**: `compose.yaml`의 `build.context` 두 줄을 같이 수정
- 위치를 고정하기 싫으면 경로를 `.env`로 빼는 방법도 있음
  - 예: `context: ${MEMBER_API_PATH:-../../../choimory-dev/choimory-dev-member-api}`
  - 평소엔 기본 경로를 쓰고, 필요할 때만 `.env`에서 바꿈
  - 지금은 혼자 이 맥에서만 쓰므로 현재 방식으로도 충분해 보임. 원하면 변경

## 확인 방법

scratchpad에 임시 compose를 만들어 확인함.

- 서비스 구성
  - `app`: `build.context`를 `${APP_CTX:-./app}`로 두어 경로를 바꿔가며 테스트
  - `db`: `image`만 있는 서비스, `profiles: [db-only]`
- 순서
  1. 정상 경로로 `up -d` 해서 이미지를 만든 뒤 `down`
  2. 없는 경로(`APP_CTX=./nope`)로 `up -d` → 기존 이미지로 기동됨
  3. 없는 경로로 `up -d --build` → `unable to prepare context: path ... not found`로 실패
  4. 없는 경로로 `--profile db-only up -d db` → db만 정상 기동
- 확인 후 컨테이너, 네트워크, 임시 이미지(`ctxtest-app`)를 정리함

---

# build.context를 GitHub 주소로

> github 리포 주소로도 바꿀수 있나? 물론 그 방식이 좋진 않을거임. 왜냐면 커밋전에 컴포즈를 올려야 할수도 있으니까. 그냥 궁금해서

## 답변

가능함. `build.context`에 로컬 경로 대신 git 저장소 주소를 넣을 수 있음.

## 방법

```yaml
member-api:
  build:
    # 형식: <저장소 주소>#<브랜치나 태그>:<하위 디렉토리>
    context: https://github.com/choimory/<레포>.git#dev
```

- `#dev`: 빌드할 브랜치, 태그, 커밋. 생략하면 기본 브랜치
- `#dev:some/dir`: Dockerfile이 레포 루트가 아닌 하위 폴더에 있을 때 경로를 붙임
- 빌드할 때마다 BuildKit이 그 시점의 원격 저장소를 받아서 빌드하므로 로컬 경로가 필요 없어짐

## 말씀하신 단점 외에 걸리는 점

- **push한 것만 빌드됨**: 커밋 전, push 전 코드는 반영되지 않음. 개발 중 확인용으로는 맞지 않음
- **비공개 레포면 인증이 필요함**: 공개 레포는 HTTPS 주소로 바로 되지만, 비공개면 아래 중 하나가 필요함
  - SSH 주소(`git@github.com:...`)로 받으면서 BuildKit에 SSH 키를 넘기는 설정
  - 토큰을 빌드 시크릿으로 넘기는 설정
- **gitignore된 파일은 빠짐**: git에 없는 파일은 빌드 컨텍스트에도 없음
  - front는 `package-lock.json`이 gitignore 대상
  - 그래서 Dockerfile의 대체 분기로 `npm ci` 대신 `npm install`이 실행되고, 의존성 버전이 로컬과 달라질 수 있음

## 참고: 레포 이름

로컬 앱 레포의 원격 주소가 폴더 이름과 다름.

| 로컬 폴더 | 원격 주소 |
|---|---|
| `choimory-dev-member-api` | `git@github.com:choimory/choimory-io-member-external-api.git` |
| `choimory-dev-front` | `git@github.com:choimory/choimory-io-front.git` |

git 주소 방식을 쓴다면 이 주소를 넣어야 함.

## 보통은 이렇게 씀

"내가 개발하지 않는 서비스는 원격 기준으로 띄우고 싶다"는 목적이라면, git 주소로 빌드하기보다 **CI에서 빌드한 이미지를 레지스트리에서 받는 방식**(`image: <레지스트리>/member-api:dev`)을 더 많이 씀.

- 빌드 없이 pull만 하니 빠름
- k8s 배포에 쓰는 이미지와 똑같은 것으로 띄울 수 있음
- choimory-dev-manifests에 Jenkins, Argo CD 구성이 있으니, 나중에 이미지 파이프라인이 생기면 고려해 볼 만함
- 지금처럼 로컬 코드를 바로 확인하는 용도라면 현재의 로컬 경로 방식이 가장 맞음

---

# build context를 .env로 빼기

> build context .env로 빼자

## 답변

프로젝트 규칙에 따라 바로 수정하지 않고 계획부터 정리함.

## 변경 계획

1. **`compose.yaml`**

```yaml
member-api:
  build:
    # 기본값은 이 맥의 레포 위치. 다른 위치면 .env의 MEMBER_API_CONTEXT로 바꿈
    context: ${MEMBER_API_CONTEXT:-../../../choimory-dev/choimory-dev-member-api}

front:
  build:
    context: ${FRONT_CONTEXT:-../../../choimory-dev/choimory-dev-front}
```

- `${변수:-기본값}` 형식이라 `.env`에 값이 없어도 지금 경로로 그대로 동작함. 사용 중인 `.env`는 수정 불필요

2. **`.env.example`**: 두 변수를 주석과 함께 추가

```bash
# 앱 레포 위치 (build.context). 상대경로는 compose.yaml 위치 기준이며 절대경로도 됨
# 비워두면 compose.yaml의 기본값(../../../choimory-dev/<레포>)을 씀
MEMBER_API_CONTEXT=../../../choimory-dev/choimory-dev-member-api
FRONT_CONTEXT=../../../choimory-dev/choimory-dev-front
```

3. **README 두 곳**: 환경변수 표에 두 변수 추가. "레포 위치가 바뀌면 `build.context`를 수정"이라고 적힌 곳은 "`.env`에서 변경"으로 수정

4. **테스트**
   - `docker compose config`로 경로가 제대로 풀리는지 확인 (기본값일 때, `.env`로 바꿨을 때 둘 다)
   - 실제 빌드도 한 번 실행(`--build`). 캐시가 있어 금방 끝남

5. **히스토리**: task3.md에 기록

## 정해야 할 것

`.env.example`에 경로 값을 적어둘지, 주석으로만 둘지.

- **값을 적어둠** (위 예시): 어디를 바꾸면 되는지 바로 보임. 다만 `cp`로 만든 `.env`에 값이 고정되어, 나중에 compose의 기본값을 바꿔도 `.env` 쪽 값이 우선함
- **주석으로만 둠** (`# MEMBER_API_CONTEXT=...`): 평소엔 compose 기본값을 쓰고, 다른 위치에서만 주석을 풀어 씀
- 혼자 이 맥에서 쓰므로 **주석으로만 두는 쪽을 추천**

---

# compose 기본값 제거, .env.example에 값 넣기

> 프로젝트 경로 컴포즈.yaml에서는 기본값 빼고, .env.example에 주석풀고 기본값 넣자

## 답변

가능함. 다만 compose에서 기본값을 빼면 **변수가 없을 때의 동작**을 정해야 해서, 임시 compose로 두 방식을 비교함.

## 변수가 없을 때 동작 비교

| compose 표기 | `.env`에 변수가 없을 때 |
|---|---|
| `${MEMBER_API_CONTEXT}` | 경고만 띄우고 빈 값이 됨. 빈 경로가 `choimory-dev/` 자기 자신으로 풀려서, 빌드할 때 `open Dockerfile: no such file or directory`라는 **원인을 짐작하기 어려운 에러**가 남. `db-only`는 정상 기동 |
| `${MEMBER_API_CONTEXT:?.env에 MEMBER_API_CONTEXT를 설정하세요}` | **어떤 명령이든 바로 멈추고** `required variable MEMBER_API_CONTEXT is missing a value: .env에 ...를 설정하세요`처럼 원인을 알려줌. 대신 `db-only`, `down`도 같이 막힘 |

- `.env`는 항상 `.env.example`을 복사해서 만드므로, 정상적으로 쓰는 동안에는 변수가 빠질 일이 없음
- 빠졌을 때 원인을 바로 알 수 있는 **`:?` 방식을 추천**

확인 방법: scratchpad에 `build.context`가 변수인 app 서비스(profile `all`)와 image만 있는 db 서비스(profile `all`, `db-only`)로 임시 compose를 만들고, 변수 없이 `--profile db-only config`와 `--profile all build`를 두 표기 방식에서 각각 실행함.

## 작업 계획

1. **`compose.yaml`**
   - 두 `context`를 기본값 없는 필수 변수(`:?`)로 변경
   - 관련 주석을 ".env에서 지정"하는 방식으로 수정
2. **`.env.example`**: 주석을 풀고 값을 넣음

```bash
# 앱 레포 위치 (build.context). 상대경로는 compose.yaml 위치 기준이며 절대경로도 됨
MEMBER_API_CONTEXT=../../../choimory-dev/choimory-dev-member-api
FRONT_CONTEXT=../../../choimory-dev/choimory-dev-front
```

3. **사용 중인 `.env`**: 같은 두 줄 추가. 지금 `.env`에는 이 변수가 없어서, 추가하지 않으면 바로 compose가 동작하지 않음
4. **README 두 곳**: 환경변수 표의 기본값을 `(주석)`에서 실제 경로로 바꾸고, 앱 레포 경로 설명 수정
5. **테스트**
   - `config`로 경로가 제대로 풀리는지 확인
   - `build` 성공 확인
   - 변수가 없을 때 에러 메시지 확인
6. **히스토리**: task4.md에 기록

---

# :? 방식

> :? 방식이 뭐야?

## 답변

`:?`는 compose 파일에서 쓰는 변수 표기법으로, **"이 값은 꼭 있어야 한다"는 뜻**. 셸(bash)의 변수 문법을 compose가 그대로 따른 것.

## compose 변수 표기 정리

| 표기 | 의미 | 값이 없을 때 |
|---|---|---|
| `${VAR}` | 그냥 변수 | 경고만 띄우고 빈 문자열로 진행 |
| `${VAR:-기본값}` | 기본값 지정 | 기본값 사용 (현재 compose가 이 방식) |
| `${VAR:?메시지}` | 필수 값 | **에러를 내고 멈춤**, 메시지 출력 |

- `:-`와 `:?`는 짝. 값이 없을 때 `-`는 대신 쓸 값을 정하고, `?`는 멈추고 알려줌

## 우리 compose에 적용하면

```yaml
member-api:
  build:
    context: ${MEMBER_API_CONTEXT:?.env에 MEMBER_API_CONTEXT를 설정하세요}
```

- `.env`에 `MEMBER_API_CONTEXT=...`가 있으면 그 값을 씀. 평소에는 아무 차이 없음
- 값이 없으면 compose가 실행 전에 멈추고 아래처럼 알려줌

```
required variable MEMBER_API_CONTEXT is missing a value: .env에 MEMBER_API_CONTEXT를 설정하세요
```

## 왜 이걸 추천했나

compose에서 기본값을 빼면 `.env`가 유일한 설정 위치가 됨. 실수로 `.env`에 값이 빠졌을 때 결과가 갈림.

- **`${VAR}`**: 빈 경로가 `choimory-dev/` 폴더 자신으로 풀려서 `Dockerfile이 없다`는 엉뚱한 에러가 남. 원인을 찾기 어려움
- **`${VAR:?메시지}`**: "`.env`에 이 값을 넣으라"고 바로 알려줌
- 단점: 변수가 빠지면 빌드와 상관없는 `db-only`나 `down`까지 막힘. compose가 명령을 실행하기 전에 파일 전체의 변수를 먼저 채우기 때문
- `.env`는 `.env.example`을 복사해 만드니 실제로 빠질 일은 거의 없음

---

# db-only에서 postgres credential 오류

> 그리고 지금 db-only 테스트중인데 redis는 접속 확인했는데 postgres가 비번이 다른지 접속이 안됨 (credential 오류)

## 답변

비밀번호 불일치로 보임.

## 원인

- postgres 데이터 디렉토리 `docker_volume/choimory-dev/postgres`는 **21:02, 첫 테스트(task1) 때 생성됨**
  - 그때 비밀번호는 테스트용으로 `.env`에 넣은 랜덤 값(32자)
- 현재 `.env`의 `POSTGRES_PASSWORD`는 6자. 이후 사용자가 변경한 것으로 보임
- postgres는 **데이터 디렉토리가 비어 있을 때(최초 기동)만** `.env`의 계정, 비밀번호를 적용함
  - 그 뒤에 `.env`를 바꿔도 DB 안의 비밀번호는 예전 랜덤 값 그대로
- Redis는 기동할 때마다 `command`로 계정을 다시 설정하므로 바뀐 비밀번호가 바로 적용됨. 그래서 Redis만 접속됨
- 확인 시점에 postgres 컨테이너가 내려가 있어 DB에 직접 붙여 확인하지는 못함. 데이터 생성 시각과 비밀번호 길이 차이로 판단함

## 해결 방법

**A. 데이터 디렉토리 초기화 (추천)**: 현재 DB에는 테스트 계정 하나뿐이라 지워도 잃을 게 없음

```bash
docker compose --profile all down
rm -rf ~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/postgres
docker compose --profile db-only up -d   # 현재 .env 비밀번호로 새로 초기화
```

- 테이블은 다음에 member-api를 띄울 때 Flyway가 다시 만듦
- 테스트 계정(`compose-test@example.com`)도 함께 사라짐

**B. 데이터는 두고 비밀번호만 변경**: 컨테이너 안에서는 비밀번호 없이 접속되므로, 그 상태에서 새 비밀번호로 변경

```bash
docker compose --profile db-only up -d
docker exec -it postgres_choimory-dev psql -U choimory -d postgres -c "ALTER USER choimory PASSWORD '<.env의 새 비밀번호>';"
```

- DataGrip 포트가 **15432**인지도 확인. 5432로 붙으면 choimory-local의 postgres로 접속됨

---

# 이미지 삭제나 --build로 해결되는지

> 아 이미지까지 지우거나 --build 추가해서 다시 하면  되겠네

## 답변

해결되지 않음. 비밀번호는 이미지가 아니라 **데이터 디렉토리 안에 저장됨**.

## 이유

| 해보는 것 | 영향 받는 것 | 비밀번호 |
|---|---|---|
| `up --build` | member-api, front 이미지만 다시 빌드. postgres는 받아온 이미지라 빌드 대상이 아님 | 그대로 |
| `down --rmi local` | 직접 빌드한 앱 이미지만 삭제 | 그대로 |
| `down --rmi all` | postgres 이미지까지 삭제. 다음 `up`에서 다시 받음 | 그대로 |
| 데이터 디렉토리 삭제 | `docker_volume/choimory-dev/postgres` | **새 `.env` 값으로 다시 초기화됨** |

- postgres 계정과 비밀번호는 최초 기동 때 `docker_volume/choimory-dev/postgres`에 기록됨
- 이 폴더는 bind mount라서 컨테이너나 이미지를 지워도 남음
- 새 컨테이너가 떠도 이 폴더를 그대로 붙이므로 예전 비밀번호를 계속 씀
- DB 데이터가 `down`해도 남게 한 설정 때문에 예전 비밀번호도 같이 남은 것

## 해결은 두 가지

```bash
# A. 데이터 초기화 (테스트 데이터뿐이라 추천)
docker compose --profile all down
rm -rf ~/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/postgres
docker compose --profile db-only up -d

# B. 데이터 유지하고 비밀번호만 변경
docker compose --profile db-only up -d
docker exec -it postgres_choimory-dev psql -U choimory -d postgres -c "ALTER USER choimory PASSWORD '<.env의 새 비밀번호>';"
```
