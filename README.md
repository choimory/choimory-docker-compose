# intro

- 프로젝트들의 docker compose들을 관리
- `docker run`에 옵션으로 붙이던 컨테이너 설정을 `compose.yaml` 파일로 적어 두고, `docker compose up -d` 한 줄로 띄움

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

- 한 번 `up -d` 하면 `restart` 정책에 따라 재부팅 후에도 자동으로 뜸. `docker compose down`을 하면 컨테이너가 삭제되어 다시 `up -d` 필요

---

# 디렉토리 구조

```txt
choimory-docker-compose/
├── choimory-dev/          # 개인프로젝트 choimory-dev 로컬 구동용 compose
│   ├── compose.yaml       # postgres, redis, member-api, front (profiles로 골라 띄움)
│   └── .env.example
├── choimory-local/        # 맥북 로컬 개발용 DB compose
│   ├── postgres/          # compose.yaml, .env.example
│   ├── redis/
│   ├── elasticsearch/
│   └── mysql/
└── choimory-server/       # 홈서버 미니PC의 개인용 앱 compose
    ├── dockge/            # compose.yaml, .env.example
    ├── homepage/
    ├── uptime-kuma/
    ├── jellyfin/
    ├── immich/
    ├── filebrowser/
    ├── vaultwarden/
    ├── adguard-home/
    └── samba/             # 호스트 apt 설치, 설정 기록용 README.md만 존재
```

---

# choimory-server

## 개요

- 홈서버 미니PC(Ubuntu Server)에서 Docker Compose로 운영하는 개인용 앱 모음
- 토이프로젝트, 개발용 DB/Redis, Argo CD 등은 k3s + GitOps로 별도 관리하며 이 저장소 범위가 아님
- 외부 인터넷에 공개하지 않음. 접속은 집 LAN과 Tailscale로만 함

## 서버 사양

| 항목 | 값 |
| --- | --- |
| CPU | AMD Ryzen 7 7735HS (8코어 16스레드) |
| GPU | Radeon 680M 내장 (VA-API, `/dev/dri/renderD128`) |
| RAM | 26Gi 사용 가능 |

## 앱 목록과 포트

| 앱 | 용도 | 이미지 | 호스트 바인딩 | tailscale serve (HTTPS) |
| --- | --- | --- | --- | --- |
| Dockge | compose 스택 웹 관리 | `louislam/dockge:1.5.0` | 127.0.0.1:5001 | 5001 |
| Homepage | 서비스 링크 대시보드 | `ghcr.io/gethomepage/homepage:v2.7.0` | 0.0.0.0:3000 | - |
| Uptime Kuma | 서비스 감시, 알림 | `louislam/uptime-kuma:2.5.8` | 127.0.0.1:3001 | 3001 |
| Jellyfin | 영상 스트리밍 | `jellyfin/jellyfin:12.4` | 0.0.0.0:8096 | - |
| Immich | 사진 백업 | `ghcr.io/immich-app/immich-server:v3.3.5` 외 | 0.0.0.0:2283 | - |
| File Browser | 웹 파일 접근 | `filebrowser/filebrowser:v2.63.23` | 0.0.0.0:8081 | - |
| Vaultwarden | 비밀번호 관리자 | `vaultwarden/server:1.37.4` | 127.0.0.1:8080 | 8443 |
| AdGuard Home (관리) | 광고 차단 DNS 관리 화면 | `adguard/adguardhome:v0.107.79` | 127.0.0.1:3002 | 3002 |
| AdGuard Home (DNS) | 클라이언트 DNS | 위와 동일 | 0.0.0.0:53 (tcp/udp) | - |
| Samba | 네트워크 드라이브 | 호스트 apt 설치 | 445 | - |

- Tailscale Funnel(인터넷 공개)은 사용하지 않음

## 네트워크 / 접근 규칙

- **관리 화면, Vaultwarden**: `127.0.0.1`에만 바인딩하고 `tailscale serve`로 HTTPS 접근
- **LAN 기기도 쓰는 앱**(Jellyfin, Immich 등): `0.0.0.0`에 바인딩
  - 공유기 포트포워딩이 없어 인터넷에서는 접근할 수 없음
  - Docker가 공개한 포트는 ufw를 우회하므로 ufw로 막는 방식에 기대지 않음
- **Jellyfin**: Cloudflare Tunnel로 노출하지 않음 (대용량 영상 전송은 Cloudflare 약관 문제 소지)
- **AdGuard Home**
  - 서버의 systemd-resolved 스텁 리스너를 끄고, 서버 자신은 외부 DNS(1.1.1.1, 8.8.8.8)를 씀. AdGuard 장애 시에도 서버를 복구할 수 있게 하기 위함
  - 서버는 `tailscale set --accept-dns=false`로 tailnet DNS를 받지 않음. 그래서 서버에서는 MagicDNS 이름이 풀리지 않음
  - Tailscale DNS에는 보조 DNS(1.1.1.1)를 함께 등록함. 광고 차단이 일부 새는 것은 감수

## 디렉토리 / 데이터 규칙

| 경로 | 용도 |
| --- | --- |
| `/data/dev/repos/choimory-docker-compose` | 이 저장소 clone 위치. Dockge stacks 경로는 이 아래 `choimory-server` |
| `/data/apps/<앱>/` | 앱별 설정, DB (bind mount) |
| `/data/nas/media` | Jellyfin 미디어 (읽기 전용 마운트) |
| `/data/nas/photos` | Immich 라이브러리 |
| `/data/nas/files` | 개인 문서 (File Browser, Samba) |
| `/data/backup` | 백업 스테이징 (DB 덤프 등) |

- 코드(이 저장소)와 데이터(`/data/apps`)를 분리하고, compose에서는 절대경로로 bind mount 함
- named volume은 쓰지 않음
- `/data/nas`는 나중에 대용량 디스크(DAS)를 마운트할 자리라 앱 설정 변경 없이 디스크만 교체 가능
- `/data/nas/photos`는 Immich가 관리하므로 File Browser와 Samba로 노출하지 않음

## compose 작성 규칙

- 앱 하나에 디렉토리 하나, 파일명은 `compose.yaml`
- 최상단에 `name:`으로 프로젝트명을 고정함
- 앱 전체를 묶는 루트 compose는 만들지 않음. Dockge 스택 관리와 `container_name` 충돌 때문이며, 일괄 기동이 필요하면 스크립트로 처리
- 이미지 태그는 버전까지 고정함. Immich의 redis와 postgres는 공식 compose의 digest를 그대로 씀
- `restart: unless-stopped`
- `TZ: Asia/Seoul`
- 실행 계정은 choimory:homeserver (`1000:1500`)
  - linuxserver 계열처럼 PUID/PGID를 지원하는 이미지는 환경변수로 지정함 (Homepage)
  - 그 외 이미지는 `user: "1000:1500"`으로 지정함 (Jellyfin, File Browser, Vaultwarden)
  - Dockge, Uptime Kuma, Immich, AdGuard Home은 컨테이너 내부 root로 실행되어 생성 파일이 root 소유가 됨
- 비밀번호, 토큰, 서버별 값은 `.env`로 분리함. `.env.example`만 커밋하고 `.env`는 gitignore 대상
- compose 파일 상단 주석에 앱 용도, 접속 방법, 사전 준비 명령(`mkdir`, `tailscale serve`)을 적음
- 주석은 `.agents/rules/dev-ops/comment.md` 규칙을 따름

## 배포 방법

1. 서버의 `/data/dev/repos/`에 저장소 clone
2. 앱 디렉토리에서 `.env.example`을 복사해 `.env` 작성
3. compose 상단 주석의 사전 준비 명령 실행
   - bind mount 경로가 없으면 Docker가 root 소유로 디렉토리를 만들어, `user`로 실행하는 컨테이너가 권한 오류로 실패함
4. `docker compose config`로 확인 후 `docker compose up -d`, 또는 Dockge 화면에서 기동

권장 기동 순서: Dockge → Homepage, Uptime Kuma → Jellyfin → Immich, File Browser, Samba → Vaultwarden, AdGuard Home

## 앱별 참고

- **Jellyfin**: VA-API 하드웨어 트랜스코딩 사용. `.env`의 `RENDER_GID`에 서버의 render 그룹 GID를 넣음 (`getent group render | cut -d: -f3`)
- **Immich**: 버전을 올릴 때는 해당 릴리스의 공식 docker-compose.yml과 비교함. 머신러닝은 CPU로 실행
- **Vaultwarden**: `DOMAIN`은 tailscale serve 주소와 포트까지 일치해야 함. `ADMIN_TOKEN`은 argon2 해시를 작은따옴표로 감싸 넣음. 계정 생성 후 `SIGNUPS_ALLOWED=false`로 변경
- **AdGuard Home**: 최초 설정 마법사에서 관리 웹 포트는 3000 그대로 둠
- **Samba**: `choimory-server/samba/README.md` 참고

## 백업

- 현재 미적용. 서버와 향후 연결할 DAS 외에 다른 저장소가 없어서 보류함
- DAS를 연결할 때 Kopia를 다시 검토함. 저장소를 DAS에 두고 `/data/apps`와 DB 덤프를 백업하는 방식
- 그 전까지 Vaultwarden 볼트는 Bitwarden 앱의 내보내기로 수동 보관함

---

# choimory-local

## 개요

- 로컬 개발할 때 쓰는 개인 어플리케이션 모음
- 필요한 것만 골라 띄울 수 있도록 서비스별 디렉토리로 분리하며, 각 디렉토리에서 `docker compose up -d`로 기동
- 서비스 간 네트워크는 공유하지 않음. 앱과 DataGrip은 `localhost:포트`로 접속
- 서비스마다 컨테이너가 하나라, 사실상 `docker run` 명령을 파일로 관리하는 용도
- `restart: always`라 재부팅 후에도 자동으로 뜸. Docker Desktop > Settings > General > Start Docker Desktop when you sign in to your computer 설정 필요

## 서비스 목록

| 서비스 | 이미지 | 호스트 바인딩 | container_name | 데이터 경로 |
| --- | --- | --- | --- | --- |
| PostgreSQL | `postgres:16.15-bookworm` | 127.0.0.1:5432 | postgres_choimory | `docker_volume/choimory/postgres` |
| Redis | `redis:8.10.3` | 127.0.0.1:6379 | redis_choimory | `docker_volume/choimory/redis` |
| Elasticsearch | `elasticsearch:8.19.23` | 127.0.0.1:9200 | elasticsearch_choimory | `docker_volume/choimory/elasticsearch` |
| MySQL | `mysql:8.4.13` | 127.0.0.1:3306 | mysql_choimory | `docker_volume/choimory/mysql` |

- 데이터 경로 기준: `${HOME}/choimory_workspace/DataGripProjects/docker_volume/`
  - `choimory/`는 choimory-local(개인용), `choimory-dev/`는 choimory-dev 프로젝트용으로 구분함

## compose 작성 규칙

- 서비스 하나에 디렉토리 하나, 파일명은 `compose.yaml`
- 프로젝트명은 `local-<서비스>` (`name: local-postgres`)로 다른 compose 프로젝트와 겹치지 않게 함
- 상시 기동이 필요하므로 `restart: always`
- 포트는 기본 포트를 쓰되 `127.0.0.1`에만 바인딩함 (공용 와이파이에서 외부 접근 차단)
- 데이터는 bind mount로 `docker_volume/choimory/<서비스>`에 저장함. compose는 `~`를 펼치지 못하므로 `${HOME}` 사용
- 이미지 태그는 버전까지 고정함
- 비밀번호는 `.env.example`에 `# 사용 시 변경` 주석과 자리표시자로 두고, 사용 시 `.env`로 복사해 수정함. `.env`는 gitignore 대상

## 실행 방법

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

## 서비스별 참고

- **PostgreSQL**: 메이저 버전 16 유지. 기존 데이터와 collation을 맞추기 위해 OS는 Debian bookworm(`-bookworm` 태그)으로 고정. 17 이상으로 올리려면 dump/restore 필요. `POSTGRES_USER`, `POSTGRES_PASSWORD`는 데이터 디렉토리가 비어 있을 때만 적용
- **Redis**: ACL로 `REDIS_USER` 계정 인증을 걸고 `default` 계정은 끔. 앱에는 username, password를 둘 다 설정. 기본 RDB 스냅샷을 `/data`에 저장
- **Elasticsearch**
  - 단일 노드. 9300(노드 간 통신)은 열지 않음
  - 보안 모드를 켜고 TLS는 끔. 클라이언트는 `elastic` 계정으로 인증 (`curl -u elastic:<비밀번호> localhost:9200`)
  - `ELASTIC_PASSWORD`는 계정 정보가 없을 때(최초 기동) `elastic` 비밀번호로 설정됨
  - 힙은 `.env`의 `ES_HEAP`(기본 `1g`)으로 고정. 지정하지 않으면 Docker Desktop VM 메모리의 절반을 힙으로 잡음
- **MySQL**: 8 계열 LTS인 8.4 사용. 기본 인증은 `caching_sha2_password`이며 `mysql_native_password`는 기본 비활성

---

# choimory-dev

## 개요

- 개인프로젝트 choimory-dev(`~/choimory_workspace/IdeaProjects/choimory-dev`)를 로컬에서 컨테이너로 띄우기 위한 compose
- 대상: `choimory-dev-member-api`(Spring Boot), `choimory-dev-front`(Next.js). `choimory-dev-sender-queue`는 미개발이라 제외
- 앱 이미지는 각 앱 레포의 `Dockerfile`로 빌드함. compose의 `build.context`는 `.env`의 `MEMBER_API_CONTEXT`, `FRONT_CONTEXT`(기본 `../../../choimory-dev/<레포>`, compose.yaml 위치 기준)로 지정함
  - compose에 기본값이 없는 필수 변수(`:?`)라, `.env`에 값이 없으면 모든 compose 명령이 "`.env`에 설정하라"는 메시지와 함께 멈춤
  - 경로는 이미지를 빌드할 때만 필요함. 이미지가 남아 있거나 `db-only`로 띄울 때는 레포가 없어도 됨
- 개발할 때만 띄우는 용도라 `restart` 정책 없음. 끌 때 컨테이너를 지우고, 앱 이미지는 남겨 다음 기동에 재사용
- IDE로 개발 중인 서비스는 빼고 나머지만 컨테이너로 띄울 수 있도록 profiles와 `--scale`로 구성함
- 상세 사용법은 `choimory-dev/README.md` 참고

## 서비스 목록

| 서비스 | 이미지 | 호스트 바인딩 | container_name | profiles | 비고 |
| --- | --- | --- | --- | --- | --- |
| postgres | `postgres:16.15-bookworm` | 127.0.0.1:15432 | postgres_choimory-dev | `all`, `db-only`, `back-only` | database `choimory_dev_member` |
| redis | `redis:8.10.3` | 127.0.0.1:16379 | redis_choimory-dev | `all`, `db-only`, `back-only` | ACL 계정 인증 |
| member-api | 앱 레포 Dockerfile 빌드 | 127.0.0.1:8080 | member-api_choimory-dev | `all`, `back-only` | Spring 프로필 `local` |
| front | 앱 레포 Dockerfile 빌드 | 127.0.0.1:3000 | front_choimory-dev | `all`, `front-only` | |

- 데이터 경로: `${HOME}/choimory_workspace/DataGripProjects/docker_volume/choimory-dev/{postgres,redis}`
- postgres, redis는 choimory-local(5432, 6379)과 겹치지 않도록 호스트 포트를 15432, 16379로 씀

## 구성

- compose 파일 하나(`choimory-dev/compose.yaml`)에 모든 서비스를 두고, 모든 서비스에 profile을 닮
  - profile이 없는 서비스는 어떤 profile을 줘도 항상 뜨므로, `db-only`처럼 일부만 띄우려면 모든 서비스에 profile이 필요함
  - `.env`의 `COMPOSE_PROFILES=all`을 기본값으로 둬서, profile 미지정 `up`/`down`이 전체를 대상으로 함
- 특정 서비스 빼기는 profile 대신 `--scale <서비스>=0` 사용. 빼는 profile을 만들면 모든 서비스에 그 이름을 달아야 해서 조합이 늘어나기 때문
- 프로젝트명은 `name: choimory-dev`, `container_name`은 `<서비스>_choimory-dev` (choimory-local의 `_choimory`와 구분)
- member-api
  - DB, Redis에는 compose 기본 네트워크의 서비스 이름(`postgres`, `redis`)으로 접속
  - `application-*.yml`의 자리표시자(`${rdb-host}` 등)를 대문자+언더스코어 환경변수(`RDB_HOST` 등)로 주입함. Spring이 relaxed binding으로 찾음
  - postgres, redis의 healthcheck가 통과한 뒤 기동함. 기동 시 Flyway가 테이블과 초기 데이터를 만듦
  - database는 Flyway가 아닌 postgres 이미지가 `POSTGRES_DB`로 최초 기동 때 만듦
- front
  - 서버(Route Handler)는 `MEMBER_API_BASE_URL=http://host.docker.internal:8080`(실행 시 환경변수)으로 호출. 호스트의 8080을 거치므로 member-api가 컨테이너든 IDE든 같은 주소로 닿음
  - 브라우저는 `NEXT_PUBLIC_MEMBER_API_BASE_URL=http://localhost:8080`(빌드 인자, 번들에 고정)으로 호출
  - `depends_on: member-api`는 `required: false`. member-api 컨테이너 없이 front를 띄우는 경우(`front-only`, `--scale member-api=0`)가 있기 때문
  - member-api의 CORS(local 프로필)가 `http://localhost:3000`을 허용하므로 3000 포트를 유지함
- `member-api`, `front`에는 `image:` 이름을 붙이지 않음. `down --rmi local`이 이름 없는 빌드 이미지만 지우기 때문

## 앱 레포의 Docker 파일

| 레포 | 파일 | 내용 |
| --- | --- | --- |
| choimory-dev-member-api | `Dockerfile` | `eclipse-temurin:21-jdk`에서 gradlew로 `:member-api:bootJar` → `eclipse-temurin:21-jre`로 실행. Gradle 의존성은 BuildKit 캐시 마운트로 재사용 |
| choimory-dev-member-api | `.dockerignore` | 빌드 결과물, IDE, 문서 제외 (`docs/flyway`는 포함) |
| choimory-dev-front | `Dockerfile` | `node:22-alpine`에서 의존성 설치, 빌드 → standalone 결과물만 실행 |
| choimory-dev-front | `.dockerignore` | `node_modules`, `.next`, `env/`, `.env*` 등 제외 |
| choimory-dev-front | `next.config.ts` | `output: "standalone"` |

- 이미지 태그는 패치 버전까지 고정함 (`eclipse-temurin:21.0.13_9-*-noble`, `node:22.23.4-alpine`)

## profiles

| profile | 포함 서비스 | 용도 |
| --- | --- | --- |
| `all` (기본) | postgres, redis, member-api, front | 전체 |
| `db-only` | postgres, redis | 백엔드를 IDE로 개발할 때 |
| `back-only` | postgres, redis, member-api | 프론트를 IDE로 개발할 때 |
| `front-only` | front | 백엔드 전부를 IDE로 돌리면서 프론트만 컨테이너로 띄울 때. DB는 `db-only`로 따로 띄움 |

- `--profile`은 `up`뿐 아니라 `down`, `ps`, `logs`, `build` 등 모든 compose 명령에 적용되는 필터. 여러 개를 주면 합친 서비스가 대상
- 명령의 `--profile`이 `.env`의 `COMPOSE_PROFILES`보다 우선함
- 새 백엔드(예: sender-queue)는 `all`, `back-only`를 달아 추가함

## 실행 방법

1. `cd choimory-dev`
2. `cp .env.example .env` 후 `changeme`를 실제 값으로 변경. `JWT_SECRET`은 32바이트 이상 (`openssl rand -base64 48`)
3. 개발 패턴에 맞게 기동

| 개발 패턴 | 명령 | 뜨는 것 |
| --- | --- | --- |
| 전체를 컨테이너로 확인 | `docker compose up -d` | 전부 |
| 백엔드를 IDE로 개발 | `docker compose --profile db-only up -d` | postgres, redis |
| 프론트를 IDE로 개발, 프론트 개발 확인 | `docker compose --profile back-only up -d` | postgres, redis, member-api |
| 백엔드 전부 IDE + 프론트는 컨테이너 | `docker compose --profile db-only --profile front-only up -d` | postgres, redis, front |
| 특정 백엔드만 IDE, 나머지는 컨테이너 | `docker compose up -d --scale member-api=0` | member-api만 빼고 전부 |
| 종료 (모든 경우) | `docker compose down` | - |

```bash
# 특정 서비스 빼기: 여러 개는 이어 쓰고, profile과 같이 쓸 수도 있음
docker compose up -d --scale member-api=0 --scale front=0
docker compose --profile back-only up -d --scale member-api=0

# 앱 코드가 바뀌어 이미지를 새로 빌드할 때 (어느 패턴 명령에나 붙임)
docker compose up -d --build

# 직접 빌드한 앱 이미지까지 지우고 싶을 때
docker compose down --rmi local
```

| 옵션 | 언제 쓰나 | 동작 |
| --- | --- | --- |
| `up --scale <서비스>=0` | 해당 서비스를 IDE로 돌릴 때 | 그 서비스 컨테이너만 빼고 기동. 이미 떠 있으면 내림 |
| `up --build` | 앱 코드(member-api, front)가 바뀌었을 때 | 이미지를 다시 빌드해 같은 태그(`latest`)로 덮어쓰고, 바뀐 컨테이너만 교체. 바뀐 게 없으면 캐시로 몇 초 안에 끝남 |
| `down --rmi local` | 앱 이미지까지 지워 디스크를 비우고 싶을 때 | `image:` 이름 없이 직접 빌드한 이미지(member-api, front)만 삭제. postgres, redis 이미지는 유지 |

- `--build` 없이 `up`하면 남아 있는 앱 이미지를 그대로 씀. 코드를 고친 뒤 `--build`를 빼면 **예전 코드로 뜸**
- `--build`로 덮어쓰면 이전 이미지는 태그 없는(`<none>`) 이미지로 남음. 쌓이면 가끔 `docker image prune`으로 정리. 빌드 캐시는 `docker builder prune`
- IDE의 front와 컨테이너 front(3000), IDE의 member-api와 컨테이너 member-api(8080)는 포트가 같아 동시에 띄우지 않음
- IDE로 member-api를 띄울 때는 DB `localhost:15432`, Redis `localhost:16379`로 설정 (choimory-local의 5432, 6379가 아님)
- DB 접속(DataGrip): `localhost:15432`, database `choimory_dev_member`, 계정은 `.env`의 `POSTGRES_USER`
- DB를 초기화하려면 down 후 `docker_volume/choimory-dev/postgres` 디렉토리를 삭제하고 다시 기동 (Flyway가 다시 적용됨)

## 환경변수 (.env)

| 변수 | 기본값(.env.example) | 설명 |
| --- | --- | --- |
| `COMPOSE_PROFILES` | `all` | profile 미지정 시 적용할 기본 profile. 지우면 profile 없는 `up`/`down`이 아무 서비스도 대상으로 삼지 않음 |
| `POSTGRES_USER` | `choimory` | postgres 계정. member-api의 `RDB_USER`로도 쓰임 |
| `POSTGRES_PASSWORD` | `changeme` | 위 계정 비밀번호 |
| `POSTGRES_DB` | `choimory_dev_member` | member-api용 database |
| `REDIS_USER` | `choimory` | redis ACL 계정 |
| `REDIS_PASSWORD` | `changeme` | 위 계정 비밀번호. `$`는 쓰지 않음 |
| `JWT_SECRET` | `changeme` | member-api JWT 서명 키 (HS256, 32바이트 이상) |
| `MEMBER_API_CONTEXT` | `../../../choimory-dev/choimory-dev-member-api` | member-api 레포 위치 (`build.context`). 필수 값 |
| `FRONT_CONTEXT` | `../../../choimory-dev/choimory-dev-front` | front 레포 위치 (`build.context`). 필수 값 |

- postgres 계정과 database는 데이터 디렉토리가 비어 있을 때(최초 기동)만 적용됨
