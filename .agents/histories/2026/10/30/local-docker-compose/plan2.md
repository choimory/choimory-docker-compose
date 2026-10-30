# 목차

- [개요](#개요)
- [기존 컨테이너에서 새 compose로 이전하는 방법](#기존-컨테이너에서-새-compose로-이전하는-방법)
  - [답변](#답변)
  - [0. 사전 확인](#0-사전-확인)
  - [1. 기존 컨테이너 중지](#1-기존-컨테이너-중지)
  - [2. 데이터 복사](#2-데이터-복사)
  - [3. 기존 컨테이너 삭제](#3-기존-컨테이너-삭제)
  - [4. 새 compose로 기동](#4-새-compose로-기동)
  - [5. 접속 확인](#5-접속-확인)
  - [6. 기존 데이터 삭제](#6-기존-데이터-삭제)
  - [되돌리기](#되돌리기)
- [README에 실행 방법 추가 여부](#readme에-실행-방법-추가-여부)
  - [답변](#답변-1)
  - [추가할 위치와 내용](#추가할-위치와-내용)
  - [넣지 않을 것](#넣지-않을-것)
- [루트 README와 choimory-local README에 실행 방법 작성](#루트-readme와-choimory-local-readme에-실행-방법-작성)
  - [답변](#답변-2)
- [choimory-local README에 상세 내용 작성](#choimory-local-readme에-상세-내용-작성)
  - [답변](#답변-3)
  - [추가한 섹션](#추가한-섹션)
- [choimory-server README에 상세 내용 작성](#choimory-server-readme에-상세-내용-작성)
  - [답변](#답변-4)
  - [추가한 섹션](#추가한-섹션-1)
  - [참고할 점](#참고할-점)
- [Redis에 username, password가 없는 이유](#redis에-username-password가-없는-이유)
  - [답변](#답변-5)
  - [걸어 두면 좋은 경우](#걸어-두면-좋은-경우)
  - [추가하는 방법](#추가하는-방법)
- [Redis ACL 적용](#redis-acl-적용)
  - [답변](#답변-6)
  - [변경한 파일](#변경한-파일)
  - [직접 해야 할 것](#직접-해야-할-것)
- [이전 작업 순서 정리](#이전-작업-순서-정리)
  - [답변](#답변-7)
  - [전체 순서](#전체-순서)
  - [.env 작성 시 주의](#env-작성-시-주의)
  - [기동 후](#기동-후)
- [config, logs 명령이 필요한지](#config-logs-명령이-필요한지)
  - [답변](#답변-8)
  - [docker compose config](#docker-compose-config)
  - [docker compose logs -f](#docker-compose-logs--f)
- [재부팅 후에도 유지되는지](#재부팅-후에도-유지되는지)
  - [답변](#답변-9)
  - [Docker Desktop 자동 시작](#docker-desktop-자동-시작)
  - [다시 뜨지 않는 경우](#다시-뜨지-않는-경우)
- [docker run 대신 yaml로 처리하는 것인지](#docker-run-대신-yaml로-처리하는-것인지)
  - [답변](#답변-10)
  - [대응 관계](#대응-관계)
  - [yaml로 바꿔서 좋은 점](#yaml로-바꿔서-좋은-점)

---

# 개요

- local-docker-compose 작업을 마무리(done1)한 뒤 이어진 대화를 정리함
- 기존 `docker run` 컨테이너를 내리고 새 compose로 올리는 방법
- 루트, choimory-local, choimory-server README에 실행 방법과 상세 내용 작성
- Redis에 ACL(username + password) 인증 적용
- compose 운영 관련 질문 (config/logs 필요 여부, 재부팅 후 유지, docker run과의 관계)

---

# 기존 컨테이너에서 새 compose로 이전하는 방법

> 이제 아까 docker ps 올려준거 있지, 그것들 내리고 이걸로 새로 올리려고 하는데 (도커 볼륨 경로 변경해야하니까) 어케하면 될까

## 답변

task1에 적은 순서와 같음. 명령은 직접 실행함

## 0. 사전 확인

```bash
docker ps -a --filter name=_choimory          # 기존 컨테이너 3개 확인
du -sh ~/DataGripProjects/DockerMount/*       # 복사할 용량 확인
ls ~/choimory_workspace/DataGripProjects/docker_volume 2>/dev/null   # 비어 있거나 없어야 함
```

- 복사 대상 폴더(`docker_volume/postgres`, `docker_volume/elasticsearch`)가 미리 있으면 안 됨
  - 있는 상태에서 `cp -R` 하면 `postgres/data`처럼 한 단계 안쪽에 복사되어, Postgres가 빈 DB로 새로 초기화됨

## 1. 기존 컨테이너 중지

```bash
docker stop postgres_choimory elasticsearch_choimory redis_choimory
```

- DB가 돌고 있는 중에 복사하면 데이터가 깨질 수 있으므로 먼저 중지

## 2. 데이터 복사

```bash
mkdir -p ~/choimory_workspace/DataGripProjects/docker_volume
cp -Rp ~/DataGripProjects/DockerMount/postgres/data ~/choimory_workspace/DataGripProjects/docker_volume/postgres
cp -Rp ~/DataGripProjects/DockerMount/elasticsearch/data ~/choimory_workspace/DataGripProjects/docker_volume/elasticsearch
```

- 이동이 아닌 복사
- `docker_volume/postgres` 바로 아래에 `PG_VERSION`, `base/` 등이 보이면 정상
- Redis는 데이터를 버리므로 복사하지 않음

## 3. 기존 컨테이너 삭제

```bash
docker rm postgres_choimory elasticsearch_choimory
docker rm -v redis_choimory      # 익명 볼륨까지 삭제
```

- 새 compose도 같은 `container_name`을 쓰므로 지우지 않으면 이름 충돌로 뜨지 않음
- 원본 데이터는 `~/DataGripProjects/DockerMount`에 그대로 남음

## 4. 새 compose로 기동

```bash
cd choimory-local/postgres         # redis, elasticsearch, mysql도 동일
cp .env.example .env
vi .env                            # changeme를 실제 값으로 변경
docker compose config
docker compose up -d
docker compose logs -f
```

- **postgres**: 기존 데이터를 쓰므로 `.env` 비밀번호는 적용되지 않고 기존 비밀번호가 유지됨. `.env`에도 기존 비밀번호를 넣어 둠
- **elasticsearch**: 로그에 `started`가 나오면 정상. 8.12에서 8.19로 데이터 변환이 있어 첫 기동이 조금 걸릴 수 있음
- **mysql**: 새로 초기화되므로 `.env` 값이 적용됨

## 5. 접속 확인

```bash
docker ps --filter name=_choimory
curl -u elastic:<비밀번호> localhost:9200
docker exec -it redis_choimory redis-cli ping     # PONG
```

- Postgres, MySQL은 DataGrip으로 접속해 기존 테이블 확인

## 6. 기존 데이터 삭제

```bash
rm -rf ~/DataGripProjects/DockerMount
```

- ES는 8.19로 한 번 뜨면 8.12로 되돌릴 수 없으므로, 며칠 써 보고 문제없을 때 삭제

## 되돌리기

- `docker compose down`으로 새 컨테이너를 내림
- 기존 `docker run` 명령으로 원래 경로(`DockerMount`)를 마운트해 다시 띄우면 원본 그대로 복구됨

---

# README에 실행 방법 추가 여부

> 실행하는법 Readme.md에도 적어줄수 있나

## 답변

가능함. README에는 히스토리를 남기지 않는 규칙이라, 언제든 쓰는 실행 방법만 넣는 것을 제안함

## 추가할 위치와 내용

- 루트 README의 `# choimory-local` 안, `## compose 작성 규칙`과 `## 서비스별 참고` 사이에 `## 실행 방법` 추가 (choimory-server의 `## 배포 방법`과 같은 위치)
- 내용
  1. 서비스 디렉토리로 이동
  2. `.env.example`을 복사해 `.env` 작성
  3. `docker compose config`로 확인 후 `docker compose up -d`
  4. 상태 확인 (로그, DataGrip, curl, redis-cli)
  5. 중지는 `docker compose down` (데이터는 bind mount 경로에 남음)
- bind mount 경로에 기존 데이터가 있으면 Postgres, MySQL은 초기화하지 않고 기존 데이터를 씀

## 넣지 않을 것

- 기존 `docker run` 컨테이너에서 옮겨 오는 절차(중지, 복사, 삭제)는 한 번만 하는 작업이라 README에 넣지 않음
- 이 절차는 task1과 각 compose 상단 주석에 있음

---

# 루트 README와 choimory-local README에 실행 방법 작성

> 루트의 README랑 choimory-local의 README에 적어줘

## 답변

- **루트 `README.md`**: `# choimory-local`의 `## compose 작성 규칙`과 `## 서비스별 참고` 사이에 `## 실행 방법` 추가
- **`choimory-local/README.md`**: 기존 `# 개요` 아래에 `---`로 구분해 `# 실행 방법` 추가. 기존 내용은 그대로 둠
- 제안 내용에서 "기존 데이터가 있으면 `.env`의 계정, 비밀번호 값은 적용되지 않음"을 덧붙임

---

# choimory-local README에 상세 내용 작성

> choimory-local의 readme에는 실행방법 외에도 choimory-local의 docker compse 관련 여러  자세한 사항들을 적어줘

## 답변

기존 `# 개요`, `# 실행 방법`은 그대로 두고 앞뒤에 섹션을 추가함

## 추가한 섹션

1. **실행 환경**: 맥북 arm64 + Docker Desktop, 파일 공유 설정 불필요
2. **디렉토리 구조**: 서비스별 파일 트리, `.env`는 gitignore 대상
3. **서비스 목록**: 이미지, 프로젝트명, container_name, 포트, 컨테이너 데이터 경로 표와 호스트 데이터 경로 트리
4. **compose 작성 규칙**: 서비스별 분리 이유, 이름 규칙, `restart: always`, `127.0.0.1` 바인딩, bind mount와 `${HOME}`, 태그 고정, 비밀번호 처리
5. **환경변수 (.env)**: 서비스별 변수, 기본값, 설명 표. 계정 값은 최초 초기화 때만 적용되고 이후 `ALTER USER`, `elasticsearch-reset-password`로 변경
6. **실행 방법** 아래 `## 자주 쓰는 명령`: ps, restart, 이미지 변경 후 재생성, down
7. **서비스별 참고**: PostgreSQL 버전 정책, Redis, ES 보안 모드와 Spring 접속, 힙 조정, 버전 업 시 복사, MySQL 인증 방식
   - 새로 넣은 내용: `MYSQL_USER`는 DB 권한 없이 만들어지므로 DB 생성 후 root로 `GRANT` 필요

---

# choimory-server README에 상세 내용 작성

> 아까 작업한 choimory-server의 정보들도 choimory-server/readme.md에 적자

## 답변

기존 `# 개요` 한 줄은 그대로 두고 범위와 접근 방식을 이어 붙인 뒤 섹션을 추가함

## 추가한 섹션

1. **서버 사양**: OS, CPU, GPU, RAM, 실행 계정
2. **디렉토리 구조**: 앱별 파일 트리, Dockge stacks 경로와의 관계
3. **앱 목록과 포트**: 이미지, 바인딩, tailscale serve 포트, 접속 주소 형식
4. **네트워크 / 접근 규칙**: 바인딩 기준, tailscale serve 등록 명령 모음, Jellyfin 외부 시청, AdGuard DNS 구성
5. **디렉토리 / 데이터 규칙**: `/data` 경로 표, 앱별 데이터 경로 표
6. **compose 작성 규칙**: 공통 규칙, 실행 계정 방식별 표
7. **환경변수 (.env)**: 앱별 변수와 설명
8. **배포 방법**: 순서, 권장 기동 순서, 자주 쓰는 명령
9. **앱별 참고**: 앱마다 H2. 각 compose 상단 주석 내용(VA-API 검증, Vaultwarden 해시 생성과 계정 생성 순서, AdGuard 사전 준비 등)을 옮김. Samba는 `samba/README.md`로 연결
10. **백업**: 보류 상태

## 참고할 점

- 홈서버 LAN IP는 README에 넣지 않고 `<서버 LAN IP 또는 Tailscale IP>`로 적음
- 백업 우선순위(Vaultwarden → Immich DB와 사진 → 나머지) 한 줄을 새로 넣음. compose 주석의 "백업 1순위"를 모은 것
- 루트 README의 `# choimory-server` 섹션과 내용이 많이 겹침. 루트를 요약 + 링크로 줄일지는 미정

---

# Redis에 username, password가 없는 이유

> choimory-local의 redis왜 username, password 없음?

## 답변

일부러 뺐음

- 기존 컨테이너도 인증 설정이 없었음. 그대로 옮기면 앱 설정을 바꾸지 않아도 됨
- `127.0.0.1:6379`에만 열려 있어 같은 와이파이의 다른 기기에서는 접속할 수 없음
- 버려도 되는 캐시라 보호할 데이터가 거의 없음

## 걸어 두면 좋은 경우

- 운영 Redis에 비밀번호가 있다면, 로컬에서도 인증이 들어간 연결 설정으로 테스트할 수 있음
- localhost 바인딩만으로는 맥북 안의 다른 프로세스는 막지 못함

## 추가하는 방법

### 1. 비밀번호만 (requirepass)

```yaml
command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
```

- 계정은 `default` 하나, 앱에는 password만 설정

### 2. username + password (ACL)

```yaml
command:
  - redis-server
  - --user default off
  - --user ${REDIS_USER} on >${REDIS_PASSWORD} ~* &* +@all
```

- Redis 6부터 지원. `default` 계정은 끄고 `choimory` 계정만 남김
- 앱에는 username, password 둘 다 설정 (Spring: `spring.data.redis.username`, `password`)

로컬 개발용이면 1번을 권하고, 운영이 ACL 계정을 쓰면 2번이 맞음

---

# Redis ACL 적용

> 2로 해줘

## 답변

2번(ACL로 username + password) 방식으로 변경함. `docker compose config`로 `command` 인자가 의도대로 펼쳐지는 것만 확인했고, 컨테이너는 띄우지 않음

## 변경한 파일

### choimory-local/redis/compose.yaml

```yaml
    command:
      - redis-server
      - --user
      - default
      - "off"
      - --user
      - ${REDIS_USER}
      - "on"
      - ">${REDIS_PASSWORD}"
      - "~*"
      - "&*"
      - "+@all"
```

- 비밀번호 없이 접속되는 `default` 계정을 끄고, `REDIS_USER` 계정에 모든 키(`~*`), 채널(`&*`), 명령(`+@all`) 허용
- 포트 주석을 공용 와이파이 차단 이유로 변경
- 상단 이전 방법에 `.env` 복사 단계와 앱 설정에 계정 정보를 추가해야 한다는 주석 추가

### choimory-local/redis/.env.example (신규)

```
REDIS_USER=choimory
# 사용 시 변경 ($는 compose 변수로 해석되므로 쓰지 않는다)
REDIS_PASSWORD=changeme
```

### README (choimory-local, 루트)

- 디렉토리 트리와 "redis는 `.env` 없음" 문구 수정
- 환경변수 표에 `REDIS_USER`, `REDIS_PASSWORD` 추가. Postgres, MySQL과 달리 기동할 때마다 적용되므로 `.env` 수정 후 `docker compose up -d`로 바로 반영됨
- 확인 명령 변경: `redis-cli --user <계정> --pass <비밀번호> --no-auth-warning ping`
- 서비스별 참고에 ACL 설명과 Spring 설정 키 추가

## 직접 해야 할 것

- `cp .env.example .env` 후 비밀번호 변경, `docker compose up -d`
- `redis-cli` 명령으로 `PONG` 확인
- 앱과 DataGrip의 Redis 접속 설정에 username, password 추가

---

# 이전 작업 순서 정리

> 그럼 이제 해야하는게 기존 컨테이너 내리고 .env 복사해서 내 계정 정보 채운다음에 docker compose up 하면 되는거?

## 답변

거의 맞음. 다만 그 사이에 **데이터 복사**와 **기존 컨테이너 삭제**가 더 있음. 빠뜨리면 Postgres와 ES가 빈 DB로 뜨거나, 같은 이름의 컨테이너가 남아 있어 뜨지 않음

## 전체 순서

```bash
# 1. 기존 컨테이너 중지
docker stop postgres_choimory elasticsearch_choimory redis_choimory

# 2. 데이터 복사 (Postgres, ES만. 대상 폴더가 미리 있으면 안 됨)
mkdir -p ~/choimory_workspace/DataGripProjects/docker_volume
cp -Rp ~/DataGripProjects/DockerMount/postgres/data ~/choimory_workspace/DataGripProjects/docker_volume/postgres
cp -Rp ~/DataGripProjects/DockerMount/elasticsearch/data ~/choimory_workspace/DataGripProjects/docker_volume/elasticsearch

# 3. 기존 컨테이너 삭제 (이름이 같아서 지우지 않으면 충돌)
docker rm postgres_choimory elasticsearch_choimory
docker rm -v redis_choimory

# 4. 서비스마다 반복 (postgres, redis, elasticsearch, mysql)
cd choimory-local/<서비스>
cp .env.example .env      # 계정 정보 채우기
docker compose config
docker compose up -d
docker compose logs -f
```

## .env 작성 시 주의

- **postgres**: 기존 데이터를 쓰므로 `.env` 값은 적용되지 않음. 기존 계정과 비밀번호를 그대로 넣어 둠
- **elasticsearch**: 여기서 정한 값이 `elastic` 계정 비밀번호가 됨. 이전에는 보안이 꺼져 있었으므로 새로 정함
- **redis, mysql**: 새로 정하는 값이 그대로 적용됨

## 기동 후

1. 접속 확인: DataGrip(Postgres, MySQL), `curl -u elastic:<비번> localhost:9200`, `redis-cli --user ... ping`
2. 앱 설정 수정: ES와 Redis 접속 정보에 계정 추가
3. 원본 삭제: 며칠 써 보고 문제없으면 `~/DataGripProjects/DockerMount` 삭제

---

# config, logs 명령이 필요한지

> docker compose up 말고 config, logs 이것도 해야해?

## 답변

필수는 아님. `up -d`만 해도 뜸. 다만 이번처럼 처음 띄울 때는 해 보는 것을 권함

## docker compose config

- `.env` 값이 compose에 제대로 들어갔는지 미리 보는 명령. 실행은 하지 않음
- `.env`를 빠뜨렸거나 변수 이름이 틀리면 경고가 뜨고 그 값은 빈 문자열이 됨
- 이 상태로 `up` 하면 Redis 계정 이름이 비거나 ES 비밀번호가 빈 값으로 뜰 수 있음
- `.env`를 처음 만든 이번에만 한 번 보면 충분함

## docker compose logs -f

- 떴는지 확인하는 용도
- `up -d`는 컨테이너를 시작만 하고 바로 끝나서, 직후에 DB가 에러로 죽어도 알 수 없음
- ES는 8.12→8.19 데이터 변환이 있어 로그를 보는 게 좋음. 마이그레이션 실패나 권한 문제가 바로 보임
- 로그 대신 `docker ps`로 상태가 계속 `Up`인지만 봐도 됨

평소에는 `docker compose up -d`만 하고, 이상할 때만 `logs`를 봄

---

# 재부팅 후에도 유지되는지

> 궁금한게 이거 docker compose up 한번만 하면 항시 유지되는거지? 재부팅해도

## 답변

맞음. 각 compose에 `restart: always`가 있어서 Docker가 켜질 때마다 컨테이너를 다시 띄움. 다만 맥에서는 조건이 하나 있음

## Docker Desktop 자동 시작

- 맥에서는 Docker Desktop이 실행돼야 Docker가 돌아감. Docker Desktop이 안 켜지면 컨테이너도 안 뜸
- Docker Desktop > Settings > General > **Start Docker Desktop when you sign in to your computer** 체크

## 다시 뜨지 않는 경우

- **`docker compose down`을 한 경우**: 컨테이너 자체가 삭제되므로 다시 `up -d` 필요
- **`docker stop`으로 멈춘 경우**: 그 자리에서는 멈춘 상태로 있지만, `always`라서 재부팅이나 Docker Desktop 재시작 후에는 다시 뜸. 계속 꺼 두려면 `down` 사용

---

# docker run 대신 yaml로 처리하는 것인지

> docker run 명령어 대신 yaml로 처리한다 이렇게 이해하면 되는거지?

## 답변

맞음. `docker run`에 옵션으로 붙이던 내용을 yaml 파일에 적어 두고, `docker compose up -d` 한 줄로 실행하는 방식

## 대응 관계

Postgres 예시

| `docker run` 옵션 | `compose.yaml` |
| --- | --- |
| `--name postgres_choimory` | `container_name: postgres_choimory` |
| `-p 127.0.0.1:5432:5432` | `ports:` |
| `-v ~/...:/var/lib/postgresql/data` | `volumes:` |
| `-e POSTGRES_PASSWORD=...` | `environment:` (값은 `.env`에서) |
| `--restart always` | `restart: always` |
| `postgres:16.15` | `image: postgres:16.15` |

## yaml로 바꿔서 좋은 점

- **설정이 파일로 남음**: 어떤 옵션으로 띄웠는지 `docker inspect`로 찾아볼 필요가 없음
- **git으로 관리됨**: 버전, 포트, 경로를 바꾼 기록이 남음
- **다시 만들기 쉬움**: 버전을 바꿀 때 `image` 태그만 고치고 `up -d` 하면 기존 컨테이너를 지우고 새로 만듦. `docker run`은 stop, rm, run을 직접 해야 했음
- **비밀번호가 파일에서 분리됨**: `.env`에 따로 두므로 명령어 기록이나 저장소에 남지 않음

compose는 원래 여러 컨테이너를 묶어서 띄우는 도구이지만, 지금은 서비스마다 컨테이너가 하나라 사실상 "`docker run`을 파일로 적어 둔 것"으로 보면 됨

---
