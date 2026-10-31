# 개요

- 로컬에서 개발할때 띄우는 db 등의 compose 관리
- `docker run`에 옵션으로 붙이던 컨테이너 설정을 `compose.yaml` 파일로 적어 두고, `docker compose up -d` 한 줄로 띄움
- 서비스마다 컨테이너가 하나라, 사실상 `docker run` 명령을 파일로 관리하는 용도
- 한 번 `up -d` 하면 `restart: always`로 재부팅 후에도 자동으로 뜸 (Docker Desktop 로그인 시 자동 시작 설정 필요)

## docker run 대신 compose로 관리하는 이유

- **설정이 파일로 남음**: 어떤 옵션으로 띄웠는지 `docker inspect`로 찾아볼 필요가 없음
- **git으로 관리됨**: 버전, 포트, 경로를 바꾼 기록이 남음
- **다시 만들기 쉬움**: 이미지 태그만 고치고 `docker compose up -d` 하면 기존 컨테이너를 지우고 새로 만듦. `docker run`은 stop, rm, run을 직접 해야 함
- **비밀번호가 분리됨**: 값은 `.env`에 따로 두므로 명령어 기록이나 저장소에 남지 않음

## docker run 옵션과의 대응

| `docker run` 옵션 | `compose.yaml` |
| --- | --- |
| `--name postgres_choimory` | `container_name: postgres_choimory` |
| `-p 127.0.0.1:5432:5432` | `ports:` |
| `-v ~/...:/var/lib/postgresql/data` | `volumes:` |
| `-e POSTGRES_PASSWORD=...` | `environment:` (값은 `.env`에서) |
| `--restart always` | `restart: always` |
| `postgres:16.15-bookworm` | `image: postgres:16.15-bookworm` |

---

# 실행 환경

- 맥북 (Apple Silicon, arm64) + Docker Desktop
- 모든 이미지는 arm64를 지원하는 공식 이미지를 사용
- 데이터 경로가 `/Users` 아래라 Docker Desktop 파일 공유 설정은 따로 필요 없음

---

# 디렉토리 구조

```txt
choimory-local/
├── postgres/
│   ├── compose.yaml
│   └── .env.example
├── redis/
│   ├── compose.yaml
│   └── .env.example
├── elasticsearch/
│   ├── compose.yaml
│   └── .env.example
└── mysql/
    ├── compose.yaml
    └── .env.example
```

- `.env`는 각 디렉토리에서 `.env.example`을 복사해 만들고, 루트 `.gitignore`로 커밋에서 제외됨

---

# 서비스 목록

| 서비스 | 이미지 | 프로젝트명 | container_name | 호스트 바인딩 | 컨테이너 데이터 경로 |
| --- | --- | --- | --- | --- | --- |
| PostgreSQL | `postgres:16.15-bookworm` | local-postgres | postgres_choimory | 127.0.0.1:5432 | `/var/lib/postgresql/data` |
| Redis | `redis:8.10.3` | local-redis | redis_choimory | 127.0.0.1:6379 | `/data` |
| Elasticsearch | `elasticsearch:8.19.23` | local-elasticsearch | elasticsearch_choimory | 127.0.0.1:9200 | `/usr/share/elasticsearch/data` |
| MySQL | `mysql:8.4.13` | local-mysql | mysql_choimory | 127.0.0.1:3306 | `/var/lib/mysql` |

## 호스트 데이터 경로

```txt
~/choimory_workspace/DataGripProjects/docker_volume/
├── choimory/          # choimory-local (개인용)
│   ├── postgres/
│   ├── redis/
│   ├── elasticsearch/
│   └── mysql/
└── choimory-dev/      # choimory-dev 프로젝트용 (../choimory-dev 참고)
```

- 경로가 없으면 Docker Desktop이 자동으로 만듦
- 컨테이너를 지워도(`docker compose down`) 데이터는 이 경로에 남음. 데이터를 초기화하려면 해당 디렉토리를 직접 삭제

---

# compose 작성 규칙

- 서비스 하나에 디렉토리 하나, 파일명은 `compose.yaml`
  - 필요한 것만 골라 띄우기 위해 한 파일 + profiles 방식 대신 디렉토리로 분리함
- 서비스끼리 네트워크를 공유하지 않음. 앱과 DataGrip은 `localhost:포트`로 접속
- 최상단 `name:`으로 프로젝트명을 `local-<서비스>`로 고정해, 다른 compose 프로젝트와 겹치지 않게 함
- `container_name`은 `<서비스>_choimory`
- 맥북을 켜면 항상 떠 있어야 하므로 `restart: always`
- 포트는 기본 포트를 쓰되 `127.0.0.1`에만 바인딩함. 카페 등 공용 와이파이에서 다른 기기가 접근하지 못하게 하기 위함
- 데이터는 named volume 대신 bind mount로 저장 위치를 고정함. compose는 `~`를 펼치지 못하므로 `${HOME}` 사용
- 이미지 태그는 패치 버전까지 고정함. `latest`는 쓰지 않음
- `TZ: Asia/Seoul`
- 비밀번호는 `.env.example`에 `# 사용 시 변경` 주석과 `changeme` 자리표시자로 두고, 사용 시 `.env`로 복사해 수정함

---

# 환경변수 (.env)

| 서비스 | 변수 | 기본값(.env.example) | 설명 |
| --- | --- | --- | --- |
| postgres | `POSTGRES_USER` | `choimory` | 최초 초기화 때 만들어지는 슈퍼유저 |
| postgres | `POSTGRES_PASSWORD` | `changeme` | 위 계정 비밀번호 |
| redis | `REDIS_USER` | `choimory` | ACL 계정 이름 |
| redis | `REDIS_PASSWORD` | `changeme` | 위 계정 비밀번호. `$`는 쓰지 않음 |
| elasticsearch | `ELASTIC_PASSWORD` | `changeme` | `elastic` 계정 비밀번호 |
| elasticsearch | `ES_HEAP` | `1g` | JVM 힙 크기. 값이 없어도 1g로 기동 |
| mysql | `MYSQL_ROOT_PASSWORD` | `changeme` | root 비밀번호 |
| mysql | `MYSQL_USER` | `choimory` | 최초 초기화 때 만들어지는 일반 계정 |
| mysql | `MYSQL_PASSWORD` | `changeme` | 위 계정 비밀번호 |

- Postgres, MySQL의 계정 변수는 데이터 디렉토리가 비어 있을 때(최초 초기화)만 적용됨. 이후 비밀번호를 바꾸려면 DB 안에서 `ALTER USER`로 변경
- `ELASTIC_PASSWORD`도 보안 정보가 없을 때(최초 기동)만 적용됨. 이후 변경은 `elasticsearch-reset-password` 사용
- Redis 계정은 기동할 때마다 `command`로 설정되므로 `.env`를 바꾸고 `docker compose up -d`만 하면 바로 적용됨

---

# 실행 방법

1. 서비스 디렉토리로 이동 (`cd choimory-local/<서비스>`)
2. `.env.example`을 복사해 `.env` 작성 (`cp .env.example .env` 후 `changeme`를 실제 값으로 변경)
3. `docker compose config`로 확인 후 `docker compose up -d`
4. 상태 확인
   - 로그: `docker compose logs -f`
   - Postgres, MySQL: DataGrip으로 `localhost:<포트>` 접속
   - Elasticsearch: `curl -u elastic:<비밀번호> localhost:9200`
   - Redis: `docker exec -it redis_choimory redis-cli --user <계정> --pass <비밀번호> --no-auth-warning ping` (`PONG`)
5. 중지: `docker compose down` (데이터는 bind mount 경로에 남음)

- bind mount 경로에 기존 데이터가 있으면 Postgres, MySQL은 초기화하지 않고 기존 데이터를 씀. 이때 `.env`의 계정, 비밀번호 값은 적용되지 않음

## 자주 쓰는 명령

```bash
docker compose ps                   # 상태 확인
docker compose restart              # 재시작
docker compose pull && docker compose up -d   # 이미지 태그 변경 후 재생성
docker compose down                 # 중지 및 컨테이너 삭제 (데이터는 유지)
docker ps --filter name=_choimory   # 로컬 DB 컨테이너 전체 확인
```

---

# 서비스별 참고

## PostgreSQL

- 메이저 버전 16 유지. 17 이상으로 올리려면 데이터 디렉토리 호환이 안 되므로 dump/restore 필요
- 마이너 버전(16.x)은 이미지 태그만 바꿔서 올려도 됨
- OS는 기존 데이터를 만든 이미지와 같은 Debian bookworm으로 고정함 (`-bookworm` 태그)
  - 기본 태그는 trixie 기반이라 glibc가 달라 collation이 바뀜. 기존 텍스트 인덱스가 어긋나고 `collation version mismatch` 경고가 뜰 수 있음
  - OS를 바꿔야 하면 `REINDEX DATABASE` 후 `ALTER DATABASE <db> REFRESH COLLATION VERSION` 실행

## Redis

- ACL로 계정 인증을 검. 비밀번호 없이 접속되는 `default` 계정은 끄고, `REDIS_USER` 계정에 전체 권한을 줌
- 앱(Spring 등) 접속 설정에 username, password를 둘 다 넣음 (`spring.data.redis.username`, `spring.data.redis.password`)
- DataGrip 등 클라이언트도 username, password로 접속
- 데이터는 버려도 되는 캐시 용도. 기본 RDB 스냅샷을 `/data`에 저장

## Elasticsearch

- 단일 노드(`discovery.type: single-node`). 9300(노드 간 통신)은 열지 않음
- 보안 모드를 켜고 TLS는 끔. HTTP로 접속하되 `elastic` 계정 인증이 필요함
  - curl: `curl -u elastic:<비밀번호> localhost:9200`
  - 앱(Spring 등): 접속 URL은 `http://localhost:9200`, 계정 정보에 `elastic` / 비밀번호 설정
- 힙은 `ES_HEAP`으로 고정. 지정하지 않으면 Docker Desktop VM 메모리의 절반을 힙으로 잡음. 데이터가 많거나 nori 등 분석기를 많이 쓰면 `2g`로 올림
- 메이저/마이너 버전을 올리면 데이터가 새 버전 형식으로 바뀌어 되돌릴 수 없음. 올리기 전 데이터 디렉토리를 복사해 둠

## MySQL

- 8.0은 2026년 4월 지원 종료라 8 계열 LTS인 8.4 사용
- 기본 인증은 `caching_sha2_password`이며 `mysql_native_password`는 기본 비활성. 오래된 드라이버로 접속이 안 되면 드라이버 버전부터 확인
- `MYSQL_USER`는 DB 권한 없이 만들어짐. 필요한 DB를 만든 뒤 root로 권한을 줌 (`GRANT ALL ON <db>.* TO 'choimory'@'%';`)
