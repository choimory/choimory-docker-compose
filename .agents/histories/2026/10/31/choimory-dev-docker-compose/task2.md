# 목차

- [개요](#개요)
- [작업 시작](#작업-시작)
  - [답변](#답변)
  - [수정한 파일](#수정한-파일)
  - [최종 profiles와 명령](#최종-profiles와-명령)
  - [테스트 결과](#테스트-결과)
  - [참고](#참고)

---

# 개요

- plan2(추가1, 추가2)에서 정한 대로 choimory-dev compose의 profiles를 개발 패턴별로 다시 구성함
  - `all`, `db-only`, `back-only`, `front-only` profile + 특정 서비스 빼기는 `--scale <서비스>=0`
  - `.env`의 `COMPOSE_PROFILES=all`로 profile 미지정 시 전체 대상
  - front → member-api 주소를 `host.docker.internal:8080`으로 바꿔, member-api가 컨테이너든 IDE든 닿게 함
- 앱 레포는 수정 없음. 커밋하지 않음

---

# 작업 시작

> 작업 시작

## 답변

compose, `.env`, README 수정과 테스트를 마침. profile별 대상 서비스, 전체 기동, member-api 빼기(`--scale`), compose 밖 member-api 연결, `db-only` 후 `front-only`, 그냥 `down`으로 전체 정리까지 모두 확인함.

## 수정한 파일

| 파일 | 내용 |
| --- | --- |
| `choimory-dev/compose.yaml` | 모든 서비스에 profiles 적용. front의 `MEMBER_API_BASE_URL`을 `http://host.docker.internal:8080`으로 변경. front의 `depends_on: member-api`에 `required: false`. 상단 주석의 실행 안내를 패턴별 명령으로 교체 |
| `choimory-dev/.env.example` | `COMPOSE_PROFILES=all` 추가 (지우면 profile 없는 up/down이 아무것도 대상으로 삼지 않는다는 주의 포함) |
| `choimory-dev/.env` | 사용 중인 파일 끝에 `COMPOSE_PROFILES=all` 추가 (gitignore 대상) |
| `choimory-dev/README.md` | 실행 방법을 개발 패턴별 명령 표로 재구성. `--scale` 사용법, 빌드/정리 옵션, IDE로 띄울 때 접속 주소, profiles와 `COMPOSE_PROFILES` 설명, 구성 메모 갱신 |
| `README.md` | 디렉토리 구조 주석, `# choimory-dev` 섹션(서비스 목록, 구성, profiles, 실행 방법, 환경변수)을 새 구성으로 갱신 |

## 최종 profiles와 명령

| 서비스 | profiles |
| --- | --- |
| postgres, redis | `all`, `db-only`, `back-only` |
| member-api | `all`, `back-only` |
| front | `all`, `front-only` |

| 개발 패턴 | 명령 |
| --- | --- |
| 전체를 컨테이너로 확인 | `docker compose up -d` |
| 백엔드를 IDE로 개발 | `docker compose --profile db-only up -d` |
| 프론트를 IDE로 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` |
| 백엔드 전부 IDE + 프론트는 컨테이너 | `docker compose --profile db-only --profile front-only up -d` |
| 특정 백엔드만 IDE, 나머지는 컨테이너 | `docker compose up -d --scale member-api=0` |
| 종료 (모든 경우) | `docker compose down` |

## 테스트 결과

| 항목 | 명령 / 방법 | 결과 |
| --- | --- | --- |
| 문법 | `docker compose config -q` | 통과 |
| profile 미지정 (`COMPOSE_PROFILES=all`) | `config --services` | postgres, redis, member-api, front |
| `--profile db-only` | `config --services` | postgres, redis |
| `--profile back-only` | `config --services` | postgres, redis, member-api |
| `--profile front-only` | `config --services` | front |
| `--profile db-only --profile front-only` | `config --services` | postgres, redis, front |
| `COMPOSE_PROFILES` 비움 | `COMPOSE_PROFILES= docker compose config --services` | 대상 없음 (`.env`에서 지우면 안 되는 이유 확인) |
| 전체 기동 | `docker compose up -d --build` | 4개 모두 기동. front의 `MEMBER_API_BASE_URL`이 `http://host.docker.internal:8080` |
| front → 컨테이너 member-api | `POST localhost:3000/api/auth/login` | 200 |
| member-api 빼기 | `docker compose up -d --scale member-api=0` | member-api 컨테이너만 내려가고 front, postgres, redis 유지 |
| front → compose 밖 member-api (IDE 실행 흉내) | member-api 이미지를 compose 밖에서 `docker run -p 127.0.0.1:8080:8080`으로 띄우고 DB/Redis는 `host.docker.internal:15432/16379`로 접속시킨 뒤 `POST localhost:3000/api/auth/login` | 200. 호스트 8080을 거쳐 compose 밖 member-api에 닿음. 확인 후 해당 컨테이너 중지(`--rm`으로 삭제) |
| `db-only` 후 `front-only` 따로 기동 | `--profile db-only up -d` → `--profile front-only up -d` | postgres, redis, front 함께 실행 중 (DB 유지) |
| 종료 | `docker compose down` (profile 없이) | front 포함 컨테이너 전부와 네트워크 삭제. 앱 이미지 2개는 유지 |
| choimory-local 영향 | `docker ps` | `postgres_choimory`, `redis_choimory`, `elasticsearch_choimory` 계속 실행 중 |

## 참고

- IDE 실행은 직접 할 수 없어서, 같은 member-api 이미지를 compose 밖에서 호스트 8080으로 띄워 "compose 네트워크 밖의 member-api"를 흉내 냄. IDE의 member-api도 호스트 8080으로 뜨면 같은 경로로 닿음
- `--scale member-api=0`을 줄 때 front가 다시 만들어짐(Recreate). 실행 중이던 front가 몇 초 재시작되는 정도라 사용에는 문제없음
- front 이미지는 다시 빌드하지 않아도 됨. `MEMBER_API_BASE_URL`은 실행 시 주입하는 값이라 컨테이너 재생성만으로 반영됨
- plan2 확인 단계에서 profile 동작 확인용으로 받은 `alpine:3.20` 이미지가 남아 있음 (필요 없으면 `docker rmi alpine:3.20`)
