# 목차

- [개요](#개요)
- [서버 사양](#서버-사양)
- [디렉토리 구조](#디렉토리-구조)
- [앱 목록과 포트](#앱-목록과-포트)
- [네트워크 / 접근 규칙](#네트워크--접근-규칙)
  - [바인딩 기준](#바인딩-기준)
  - [tailscale serve 등록](#tailscale-serve-등록)
  - [Jellyfin 외부 시청](#jellyfin-외부-시청)
  - [AdGuard Home DNS 구성](#adguard-home-dns-구성)
- [디렉토리 / 데이터 규칙](#디렉토리--데이터-규칙)
  - [앱별 데이터 경로](#앱별-데이터-경로)
- [compose 작성 규칙](#compose-작성-규칙)
  - [실행 계정](#실행-계정)
- [환경변수 (.env)](#환경변수-env)
- [배포 방법](#배포-방법)
  - [자주 쓰는 명령](#자주-쓰는-명령)
- [앱별 참고](#앱별-참고)
  - [Dockge](#dockge)
  - [Homepage](#homepage)
  - [Uptime Kuma](#uptime-kuma)
  - [Jellyfin](#jellyfin)
  - [Immich](#immich)
  - [File Browser](#file-browser)
  - [Vaultwarden](#vaultwarden)
  - [AdGuard Home](#adguard-home)
  - [Samba](#samba)
- [백업](#백업)

---

# 개요

- 개인 홈서버에 설치한 어플리케이션들의 compose 관리
- 토이프로젝트, 개발용 DB/Redis, Argo CD 등은 k3s + GitOps로 별도 관리하며 이 디렉토리 범위가 아님
- 외부 인터넷에 공개하지 않음. 접속은 집 LAN과 Tailscale로만 함

---

# 서버 사양

| 항목 | 값 |
| --- | --- |
| OS | Ubuntu Server |
| CPU | AMD Ryzen 7 7735HS (8코어 16스레드) |
| GPU | Radeon 680M 내장 (VA-API, `/dev/dri/renderD128`) |
| RAM | 26Gi 사용 가능 |
| 실행 계정 | choimory:homeserver (`1000:1500`) |

---

# 디렉토리 구조

```txt
choimory-server/
├── dockge/            # compose.yaml, .env.example
├── homepage/          # compose.yaml, .env.example
├── uptime-kuma/       # compose.yaml
├── jellyfin/          # compose.yaml, .env.example
├── immich/            # compose.yaml, .env.example
├── filebrowser/       # compose.yaml
├── vaultwarden/       # compose.yaml, .env.example
├── adguard-home/      # compose.yaml
└── samba/             # 호스트 apt 설치, 설정 기록용 README.md만 존재
```

- 이 디렉토리가 그대로 Dockge의 stacks 경로가 됨. 디렉토리 하나가 Dockge 스택 하나
- `.env`는 각 디렉토리에서 `.env.example`을 복사해 만들고, 루트 `.gitignore`로 커밋에서 제외됨

---

# 앱 목록과 포트

| 앱 | 용도 | 이미지 | 호스트 바인딩 | tailscale serve (HTTPS) |
| --- | --- | --- | --- | --- |
| Dockge | compose 스택 웹 관리 | `louislam/dockge:1.5.0` | 127.0.0.1:5001 | 5001 |
| Homepage | 서비스 링크 대시보드 | `ghcr.io/gethomepage/homepage:v2.7.0` | 0.0.0.0:3000 | - |
| Uptime Kuma | 서비스 감시, 알림 | `louislam/uptime-kuma:2.5.8` | 127.0.0.1:3001 | 3001 |
| Jellyfin | 영상 스트리밍 | `jellyfin/jellyfin:12.4` | 0.0.0.0:8096 | - |
| Immich | 사진 백업 (구글 포토 대체) | `ghcr.io/immich-app/immich-server:v3.3.5` 외 | 0.0.0.0:2283 | - |
| File Browser | 웹 파일 접근 | `filebrowser/filebrowser:v2.63.23` | 0.0.0.0:8081 | - |
| Vaultwarden | 비밀번호 관리자 | `vaultwarden/server:1.37.4` | 127.0.0.1:8080 | 8443 |
| AdGuard Home (관리) | 광고 차단 DNS 관리 화면 | `adguard/adguardhome:v0.107.79` | 127.0.0.1:3002 | 3002 |
| AdGuard Home (DNS) | 클라이언트 DNS | 위와 동일 | 0.0.0.0:53 (tcp/udp) | - |
| Samba | 네트워크 드라이브 | 호스트 apt 설치 | 445 | - |

- `0.0.0.0` 앱 접속: `http://<서버 LAN IP 또는 Tailscale IP>:<포트>`
- tailscale serve 앱 접속: `https://choimory-server.<tailnet>.ts.net:<포트>`
- Tailscale Funnel(인터넷 공개)은 사용하지 않음

---

# 네트워크 / 접근 규칙

## 바인딩 기준

- **관리 화면, Vaultwarden**: `127.0.0.1`에만 바인딩하고 `tailscale serve`로 HTTPS 접근
  - Dockge는 Docker 소켓을 마운트해 사실상 root 권한이므로 반드시 Tailscale로만 접근
  - Vaultwarden은 웹 볼트와 Bitwarden 앱이 HTTPS를 요구하므로 tailscale serve가 TLS를 처리
- **LAN 기기도 쓰는 앱**(Homepage, Jellyfin, Immich, File Browser): `0.0.0.0`에 바인딩
  - 공유기 포트포워딩이 없어 인터넷에서는 접근할 수 없음
  - Docker가 공개한 포트는 ufw를 우회하므로 ufw로 막는 방식에 기대지 않음

## tailscale serve 등록

```bash
sudo tailscale serve --bg --https=5001 http://127.0.0.1:5001   # Dockge
sudo tailscale serve --bg --https=3001 http://127.0.0.1:3001   # Uptime Kuma
sudo tailscale serve --bg --https=8443 http://127.0.0.1:8080   # Vaultwarden
sudo tailscale serve --bg --https=3002 http://127.0.0.1:3002   # AdGuard Home 관리 화면
sudo tailscale serve status                                    # 등록 확인
```

- Tailscale 관리 콘솔 > DNS > HTTPS Certificates 활성화 필요

## Jellyfin 외부 시청

- Cloudflare Tunnel로 노출하지 않음 (대용량 영상 전송은 Cloudflare 약관 문제 소지)
- 밖에서는 Tailscale을 켜고 접속

## AdGuard Home DNS 구성

- 서버의 systemd-resolved 스텁 리스너를 끄고, 서버 자신은 외부 DNS(1.1.1.1, 8.8.8.8)를 씀
  - AdGuard 장애 시에도 apt, docker pull, tailscale로 서버를 복구할 수 있게 하기 위함
- 서버는 `tailscale set --accept-dns=false`로 tailnet DNS를 받지 않음. 그래서 서버에서는 MagicDNS 이름이 풀리지 않음
- Tailscale DNS(전역 네임서버)에 서버 Tailscale IP를 등록하면 밖에서도 광고 차단이 적용됨
- 보조 DNS(1.1.1.1)를 함께 등록함. 광고 차단이 일부 새는 대신 AdGuard 장애 시에도 인터넷이 유지됨
- 적용은 맥북 한 대에서 먼저 써보고 안정되면 Tailscale DNS에 등록

---

# 디렉토리 / 데이터 규칙

| 경로 | 용도 |
| --- | --- |
| `/data/dev/repos/choimory-docker-compose` | 이 저장소 clone 위치. Dockge stacks 경로는 이 아래 `choimory-server` |
| `/data/apps/<앱>/` | 앱별 설정, DB (bind mount) |
| `/data/nas/media` | Jellyfin 미디어 (읽기 전용 마운트), Samba `media` 공유 |
| `/data/nas/photos` | Immich 라이브러리 |
| `/data/nas/files` | 개인 문서 (File Browser, Samba `files` 공유) |
| `/data/backup` | 백업 스테이징 (DB 덤프 등) |

- 코드(이 저장소)와 데이터(`/data/apps`)를 분리하고, compose에서는 절대경로로 bind mount 함
- named volume은 쓰지 않음
- `/data/nas`는 나중에 대용량 디스크(DAS)를 마운트할 자리라 앱 설정 변경 없이 디스크만 교체 가능
- `/data/nas/photos`는 Immich가 관리하므로 File Browser와 Samba로 노출하지 않음. 밖에서 지우거나 옮기면 Immich 데이터가 깨짐

## 앱별 데이터 경로

| 앱 | 호스트 경로 |
| --- | --- |
| Dockge | `/data/apps/dockge/data` |
| Homepage | `/data/apps/homepage/config` |
| Uptime Kuma | `/data/apps/uptime-kuma/data` |
| Jellyfin | `/data/apps/jellyfin/{config,cache}`, `/data/nas/media` (ro) |
| Immich | `/data/apps/immich/{postgres,model-cache}`, `/data/nas/photos` |
| File Browser | `/data/apps/filebrowser/{database,config}`, `/data/nas/files` |
| Vaultwarden | `/data/apps/vaultwarden/data` |
| AdGuard Home | `/data/apps/adguard-home/{work,conf}` |

---

# compose 작성 규칙

- 앱 하나에 디렉토리 하나, 파일명은 `compose.yaml`
- 최상단에 `name:`으로 프로젝트명을 고정함
- 앱 전체를 묶는 루트 compose는 만들지 않음. Dockge 스택 관리와 `container_name` 충돌 때문이며, 일괄 기동이 필요하면 스크립트로 처리
- 이미지 태그는 버전까지 고정함. Immich의 redis와 postgres는 공식 compose의 digest를 그대로 씀
- `restart: unless-stopped`
- `TZ: Asia/Seoul`
- 비밀번호, 토큰, 서버별 값은 `.env`로 분리함. `.env.example`만 커밋하고 `.env`는 gitignore 대상
- compose 파일 상단 주석에 앱 용도, 접속 방법, 사전 준비 명령(`mkdir`, `tailscale serve`)을 적음
- 주석은 `.agents/rules/dev-ops/comment.md` 규칙을 따름

## 실행 계정

| 방식 | 대상 |
| --- | --- |
| `PUID`/`PGID` 환경변수 (`1000`/`1500`) | Homepage |
| `user: "1000:1500"` | Jellyfin, File Browser, Vaultwarden |
| 컨테이너 내부 root (생성 파일이 root 소유) | Dockge, Uptime Kuma, Immich, AdGuard Home |

- linuxserver 계열처럼 PUID/PGID를 지원하는 이미지만 환경변수로 지정하고, 그 외에는 `user`로 지정함

---

# 환경변수 (.env)

| 앱 | 변수 | 설명 |
| --- | --- | --- |
| dockge | `STACKS_DIR` | stacks 경로 절대경로. 컨테이너 안팎 경로를 같게 마운트함 |
| homepage | `HOMEPAGE_ALLOWED_HOSTS` | 접속 주소(`host:port`) 목록. LAN IP, Tailscale IP, MagicDNS 이름을 쉼표로 구분 |
| jellyfin | `RENDER_GID` | 서버 render 그룹 GID (`getent group render \| cut -d: -f3`) |
| immich | `UPLOAD_LOCATION` | 사진 저장 위치 (`/data/nas/photos`) |
| immich | `DB_DATA_LOCATION` | Immich Postgres 데이터 위치 (`/data/apps/immich/postgres`) |
| immich | `IMMICH_VERSION` | Immich 버전 (`v3.3.5`) |
| immich | `DB_PASSWORD` | Immich Postgres 비밀번호. A-Za-z0-9만 사용 |
| vaultwarden | `DOMAIN` | tailscale serve 주소, 포트까지 포함 |
| vaultwarden | `SIGNUPS_ALLOWED` | 본인 계정 생성 후 `false` |
| vaultwarden | `ADMIN_TOKEN` | `/admin` 토큰의 argon2 해시. 작은따옴표로 감쌈 |

---

# 배포 방법

1. 서버의 `/data/dev/repos/`에 저장소 clone
2. 앱 디렉토리에서 `.env.example`을 복사해 `.env` 작성
3. compose 상단 주석의 사전 준비 명령 실행
   - bind mount 경로가 없으면 Docker가 root 소유로 디렉토리를 만들어, `user`로 실행하는 컨테이너가 권한 오류로 실패함
   ```bash
   mkdir -p /data/apps/<앱>/...
   ```
4. `docker compose config`로 확인 후 `docker compose up -d`, 또는 Dockge 화면에서 기동
5. 필요한 앱은 `tailscale serve` 등록

권장 기동 순서: Dockge → Homepage, Uptime Kuma → Jellyfin → Immich, File Browser, Samba → Vaultwarden, AdGuard Home

## 자주 쓰는 명령

```bash
docker compose ps                              # 상태 확인
docker compose logs -f                         # 로그 확인
docker compose pull && docker compose up -d    # 이미지 태그 변경 후 재생성
docker compose down                            # 중지 및 컨테이너 삭제 (데이터는 유지)
```

- Dockge 화면에서 compose를 수정하면 저장소 파일이 바로 바뀌므로 `git status`로 변경사항을 확인함

---

# 앱별 참고

## Dockge

- Docker 소켓(`/var/run/docker.sock`)을 마운트함. 화면 접근은 Tailscale로만 제한
- compose 파일 경로를 호스트에 그대로 전달하므로 `STACKS_DIR`을 컨테이너 안팎 같은 경로로 마운트함

## Homepage

- 서비스 목록은 `/data/apps/homepage/config/services.yaml` 등 설정 파일로 관리 (최초 기동 시 기본 파일 생성)
- Docker 소켓은 마운트하지 않음. 컨테이너 상태 표시가 필요하면 docker-socket-proxy를 붙임
- `HOMEPAGE_ALLOWED_HOSTS`에 없는 주소로 접속하면 요청을 거부함

## Uptime Kuma

- AdGuard Home은 HTTP가 아닌 DNS 모니터 타입으로 `<Tailscale IP>:53`을 감시해야 실제 DNS 응답을 확인할 수 있음

## Jellyfin

- VA-API 하드웨어 트랜스코딩 사용. `/dev/dri/renderD128`을 넘기고 render 그룹(`RENDER_GID`)을 추가함
- 관리 화면 > 재생 > 트랜스코딩에서 VA-API, 장치 `/dev/dri/renderD128` 지정
- 검증: `docker exec -it jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128`
- 미디어는 읽기 전용 마운트. 메타데이터는 `/config`에 저장

## Immich

- 공식 릴리스의 docker-compose.yml을 기준으로 경로와 재시작 정책만 바꿈
- 버전을 올릴 때는 해당 릴리스의 공식 compose와 비교해 redis/database 이미지 변경 여부를 확인하고, 릴리스 노트의 Breaking Changes 확인
- redis(Valkey), postgres는 외부에 포트를 노출하지 않음. postgres 이미지를 다른 것으로 바꾸면 기동하지 않음
- 머신러닝은 CPU로 실행 (ROCm은 이미지가 크고 실험적). 동영상 하드웨어 트랜스코딩이 필요하면 `devices` 주석 해제
- DB는 파일 복사가 아니라 `pg_dump`로 백업

## File Browser

- 파일 탐색의 주 수단은 Samba이고, File Browser는 Samba가 없는 기기에서 가끔 쓰는 용도
- `/data/nas/files`만 노출
- 최초 admin 비밀번호는 첫 기동 로그에 출력됨 (`docker logs filebrowser`)

## Vaultwarden

- `DOMAIN`은 tailscale serve 주소와 포트까지 일치해야 웹 볼트, 첨부파일 링크, 패스키가 정상 동작함
- `ADMIN_TOKEN` 해시 생성: `docker run --rm -it vaultwarden/server:1.37.4 /vaultwarden hash`. `$`가 compose 변수로 해석되지 않게 작은따옴표로 감쌈
- 계정 생성 순서: `SIGNUPS_ALLOWED=true`로 기동 → 본인 계정 생성 → `false`로 바꾸고 `docker compose up -d`
- 데이터(`/data/apps/vaultwarden/data`)는 백업 1순위

## AdGuard Home

- 사전 준비 (53번 포트 확보, 서버 자신은 외부 DNS 사용)
  ```bash
  sudo mkdir -p /etc/systemd/resolved.conf.d
  printf "[Resolve]\nDNS=1.1.1.1 8.8.8.8\nDNSStubListener=no\n" | sudo tee /etc/systemd/resolved.conf.d/adguardhome.conf
  sudo mv /etc/resolv.conf /etc/resolv.conf.backup
  sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
  sudo systemctl restart systemd-resolved
  sudo tailscale set --accept-dns=false
  ```
- 최초 설정 마법사에서 관리 웹 포트는 3000 그대로 둠 (호스트 3002 → 컨테이너 3000). DNS는 모든 인터페이스, 53번

## Samba

- 445 포트, 호스트 계정과 권한에 엮여 있어 컨테이너가 아닌 호스트에 apt로 설치
- 공유: `files`(`/data/nas/files`), `media`(`/data/nas/media`). `force group = homeserver`로 컨테이너(`1000:1500`)와 권한을 맞춤
- 설치, 설정, 가족 계정 추가 방법은 `samba/README.md` 참고

---

# 백업

- 현재 미적용. 서버와 향후 연결할 DAS 외에 다른 저장소가 없어서 보류함
- DAS를 연결할 때 Kopia를 다시 검토함. 저장소를 DAS에 두고 `/data/apps`와 DB 덤프를 백업하는 방식
- 그 전까지 Vaultwarden 볼트는 Bitwarden 앱의 내보내기로 수동 보관함
- 백업 우선순위: Vaultwarden 데이터, Immich DB(`pg_dump`)와 사진, 나머지 `/data/apps`
