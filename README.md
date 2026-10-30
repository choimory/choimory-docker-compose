# intro

- 프로젝트들의 docker compose들을 관리

---

# 디렉토리 구조

```txt
choimory-docker-compose/
├── choimory-dev/          # 개인프로젝트 choimory-dev 로컬 구동용 compose (미작성)
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

## 서비스 목록

| 서비스 | 이미지 | 호스트 바인딩 | container_name | 데이터 경로 |
| --- | --- | --- | --- | --- |
| PostgreSQL | `postgres:16.15` | 127.0.0.1:5432 | postgres_choimory | `docker_volume/postgres` |
| Redis | `redis:8.10.3` | 127.0.0.1:6379 | redis_choimory | `docker_volume/redis` |
| Elasticsearch | `elasticsearch:8.19.23` | 127.0.0.1:9200 | elasticsearch_choimory | `docker_volume/elasticsearch` |
| MySQL | `mysql:8.4.13` | 127.0.0.1:3306 | mysql_choimory | `docker_volume/mysql` |

- 데이터 경로 기준: `${HOME}/choimory_workspace/DataGripProjects/docker_volume/`

## compose 작성 규칙

- 서비스 하나에 디렉토리 하나, 파일명은 `compose.yaml`
- 프로젝트명은 `local-<서비스>` (`name: local-postgres`)로 다른 compose 프로젝트와 겹치지 않게 함
- 상시 기동이 필요하므로 `restart: always`
- 포트는 기본 포트를 쓰되 `127.0.0.1`에만 바인딩함 (공용 와이파이에서 외부 접근 차단)
- 데이터는 bind mount로 `docker_volume/<서비스>`에 저장함. compose는 `~`를 펼치지 못하므로 `${HOME}` 사용
- 이미지 태그는 버전까지 고정함
- 비밀번호는 `.env.example`에 `# 사용 시 변경` 주석과 자리표시자로 두고, 사용 시 `.env`로 복사해 수정함. `.env`는 gitignore 대상

## 서비스별 참고

- **PostgreSQL**: 메이저 버전 16 유지. 17 이상으로 올리려면 dump/restore 필요. `POSTGRES_USER`, `POSTGRES_PASSWORD`는 데이터 디렉토리가 비어 있을 때만 적용
- **Redis**: 비밀번호 없음 (localhost 전용). 기본 RDB 스냅샷을 `/data`에 저장
- **Elasticsearch**
  - 단일 노드. 9300(노드 간 통신)은 열지 않음
  - 보안 모드를 켜고 TLS는 끔. 클라이언트는 `elastic` 계정으로 인증 (`curl -u elastic:<비밀번호> localhost:9200`)
  - `ELASTIC_PASSWORD`는 계정 정보가 없을 때(최초 기동) `elastic` 비밀번호로 설정됨
  - 힙은 `.env`의 `ES_HEAP`(기본 `1g`)으로 고정. 지정하지 않으면 Docker Desktop VM 메모리의 절반을 힙으로 잡음
- **MySQL**: 8 계열 LTS인 8.4 사용. 기본 인증은 `caching_sha2_password`이며 `mysql_native_password`는 기본 비활성
