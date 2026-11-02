# 목차

- [개요](#개요)
- [서버 사양](#서버-사양)
- [디렉토리 구조](#디렉토리-구조)
- [앱 목록과 포트](#앱-목록과-포트)
- [네트워크 / 접근 규칙](#네트워크--접근-규칙)
  - [바인딩 기준](#바인딩-기준)
  - [tailscale serve 등록](#tailscale-serve-등록)
  - [Jellyfin 외부 시청](#jellyfin-외부-시청)
  - [Tailscale 클라이언트 서브넷 경로](#tailscale-클라이언트-서브넷-경로)
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
| LAN IP | `192.168.10.201` (ipTIME DHCP 고정 할당. 자동 할당 범위 `.2 ~ .200` 밖의 `.201` 이상을 고정 기기용으로 사용) |
| Tailscale | `choimory-server` (MagicDNS) |
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
- **LAN 기기도 쓰는 앱**(Homepage, Jellyfin, Immich): `0.0.0.0`에 바인딩
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
- 밖에서는 Tailscale을 켜고 Tailscale 주소(`choimory-server.<tailnet>.ts.net:8096`)로 접속. 모바일 앱에도 LAN 주소가 아닌 Tailscale 주소로 등록
- 속도 상한은 원룸 인터넷 업로드 속도와 밖의 네트워크 속도 중 느린 쪽이라, 밖에서는 화질을 낮춰서 봄

## Tailscale 클라이언트 서브넷 경로

- 서버는 서브넷 라우터로 `192.168.10.0/24`를 광고함 (밖에서 Tailscale이 없는 집 기기에 접속하는 용도)
- 집 LAN 안에서 쓰는 기기(데스크톱, 맥북)는 서브넷 경로를 받지 않음: `tailscale set --accept-routes=false`
  - 맥북도 `true`면 집 와이파이에서 같은 헤어핀이 생겨 매우 느렸고, `false`로 바꾼 뒤 정상
  - 받아들이면 Tailscale 통신 경로가 꼬여 공유기 밖 공인 IP로 나갔다 들어오는 헤어핀이 생기고, 동영상 스트리밍처럼 대용량 전송이 크게 느려짐
  - 끄면 LAN 주소는 랜으로 바로, Tailscale 주소도 집 안 직접 연결(`tailscale ping`이 `via 192.168.10.201:41641`)
- 이 설정은 기기 단위로 어디서든 적용됨. 끈 기기는 밖에서 `192.168.10.x` 주소(공유기 관리 화면 등)에 못 들어가지만, Tailscale 주소로 접속하는 서버 앱은 그대로 사용 가능
- 모든 클라이언트가 서브넷 경로를 쓰지 않으면 서버의 광고도 해제 가능 (`sudo tailscale set --advertise-routes=`, exit node 설정은 유지). 현재는 광고를 유지한 채 클라이언트에서만 받지 않음
- 밖에서 공유기 관리 화면이 필요하면 SSH 터널 사용
  ```bash
  # 내 localhost:8081을 서버 기준 192.168.10.1:80(공유기 관리 화면)으로 연결. 브라우저에서 http://localhost:8081
  ssh -L 8081:192.168.10.1:80 choimory@choimory-server
  ```

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
| `/data/dev/choimory/repo/choimory-docker-compose` | 이 저장소 clone 위치. Dockge stacks 경로는 이 아래 `choimory-server` |
| `/data/apps/<앱>/` | 앱별 설정, DB (bind mount) |
| `/data/storage/media` | Jellyfin 미디어 (읽기 전용 마운트), Samba `media` 공유 |
| `/data/storage/photos` | Immich 라이브러리 |
| `/data/storage/files` | 개인 문서 (Samba `files` 공유) |
| `/data/backup` | 백업 스테이징 (DB 덤프 등) |

- 코드(이 저장소)와 데이터(`/data/apps`)를 분리하고, compose에서는 절대경로로 bind mount 함
- named volume은 쓰지 않음
- `/data/storage`는 앱이 보는 대용량 데이터 경로로 고정함. 디스크를 바꿔도 앱 설정은 그대로 (아래 스토리지 / 마운트 구조 참고)
- `/data/storage/photos`는 Immich가 관리하므로 Samba로 노출하지 않음. 밖에서 지우거나 옮기면 Immich 데이터가 깨짐

## 스토리지 / 마운트 구조

### 경로를 두 층으로 나눔

| 층 | 경로 | 이름 기준 | 바뀌는 시점 |
| --- | --- | --- | --- |
| 장치 | `/mnt/<장치>` (`/mnt/disk-a`, `/mnt/das` 등) | 장치 이름 | 디스크를 추가·교체할 때 |
| 앱 | `/data/storage/...` | 역할(무엇을 담는지) | 바뀌지 않음 |

- 디스크는 `/mnt/<장치>`에 마운트하고, 그 안의 폴더를 `/data/storage/...`에 bind mount로 연결함
- 앱(Jellyfin, Samba, Immich)은 `/data/storage`만 바라보므로 디스크가 외장하드든 DAS든 앱 설정을 바꾸지 않음
- 경로 이름을 `nas`나 `das`로 짓지 않은 이유: NAS 장비는 없고, DAS 도입 전에는 같은 경로가 내장 SSD에 있으며, 나중에 장치를 바꾸면 이름이 실제와 어긋나기 때문

### 단계별 구성

**현재 (내장 SSD만)**: `/data/storage` 하위 폴더가 그대로 내장 SSD에 있음

**외장하드 허브 연결 시**

```txt
/mnt/disk-a                  ← 외장하드 A
/mnt/disk-b                  ← 외장하드 B (백업 전용, Kopia 저장소)

/data/storage/media   → /mnt/disk-a/media   (bind mount)
/data/storage/files   → /mnt/disk-a/files   (bind mount)
/data/storage/photos  → 내장 SSD 그대로 (대체 불가 데이터라 가장 안정적인 곳에 두고 외장하드 B로 백업)
```

**DAS 도입 시**

```txt
/mnt/das                     ← DAS

/data/storage/media   → /mnt/das/media
/data/storage/files   → /mnt/das/files
/data/storage/photos  → 내장 SSD 유지 또는 /mnt/das/photos
/mnt/disk-a, disk-b   → 백업용으로 전환하거나 은퇴
```

- 옮길 때는 데이터를 rsync로 복사하고 fstab bind mount 줄의 왼쪽 경로만 바꿈

### fstab 예시

```txt
# 장치 마운트 (장치가 바뀌면 이 줄만 수정)
UUID=xxxx  /mnt/disk-a  ext4  defaults,nofail,x-systemd.device-timeout=10s  0 2

# 앱 경로 연결 (장치가 바뀌면 왼쪽 경로만 수정)
/mnt/disk-a/media  /data/storage/media  none  bind,nofail  0 0
/mnt/disk-a/files  /data/storage/files  none  bind,nofail  0 0
```

- `nofail`: 디스크가 연결되지 않아도 서버가 부팅되게 함
- `x-systemd.device-timeout=10s`: 디스크가 없을 때 부팅이 오래 멈추지 않게 함
- UUID는 `sudo blkid`로 확인. `/dev/sdb` 같은 장치명은 연결 순서에 따라 바뀌므로 쓰지 않음
- 수정 후 재부팅 전에 `sudo mount -a`로 오류가 없는지 확인

### 리눅스 마운트 개념

- 우분투 서버는 USB 디스크를 꽂아도 자동으로 어디에도 마운트하지 않음. `lsblk`에 `/dev/sdb` 같은 장치로만 보임
- 어디에 붙일지는 fstab 또는 `mount` 명령으로 직접 정함. 장치 종류(외장하드, DAS)에 따라 경로가 정해지는 것이 아님
- 마운트하면 하위 폴더가 생기는 것이 아니라, 마운트 지점 폴더 자체가 그 디스크의 최상위가 됨
  ```bash
  sudo mkdir -p /mnt/disk-a
  sudo mount /dev/sdb1 /mnt/disk-a
  ls /mnt/disk-a        # 외장하드 안의 파일이 바로 보임 (/mnt/disk-a/외장하드/... 가 아님)
  ```
- bind mount는 이미 마운트된 경로의 특정 폴더를 다른 경로에서도 보이게 연결하는 것. 디스크 안의 `media` 폴더를 `/data/storage/media`로 보이게 할 때 사용
- 마운트 지점에 원래 파일이 있었으면, 마운트하는 동안 그 파일은 가려짐 (삭제되는 것은 아니고 마운트 해제하면 다시 보임). 그래서 마운트 지점은 빈 폴더로 두고, 내장 SSD에 있던 데이터는 디스크로 먼저 옮긴 뒤 마운트함

### 외장하드 허브 사용 시 주의

- 2.5인치(USB 전원) 외장하드를 여러 개 연결할 때는 유전원 허브를 사용함
- USB 허브 위에 RAID(mdadm, ZFS)를 구성하지 않음. 디스크가 잠깐 끊기면 배열이 깨지거나 재구성에 들어감. 디스크는 하나씩 독립적으로 사용
- 여러 디스크의 용량을 합쳐야 하면 RAID 대신 mergerfs를 검토 (디스크 하나가 빠져도 나머지 파일은 유지됨)
- 파일시스템은 ext4로 포맷함. exFAT은 소유권·권한이 없어 `1000:1500` 권한 구조가 적용되지 않음
- USB 너머 SMART 확인은 `sudo smartctl -a -d sat /dev/sdX`
- 디스크가 빠진 상태로 컨테이너가 뜨면 비어 있는 마운트 지점(내장 SSD)에 파일을 쓸 수 있으므로, Samba 쪽은 마운트 상태를 감시함

## 앱별 데이터 경로

| 앱 | 호스트 경로 |
| --- | --- |
| Dockge | `/data/apps/dockge/data` |
| Homepage | `/data/apps/homepage/config` |
| Uptime Kuma | `/data/apps/uptime-kuma/data` |
| Jellyfin | `/data/apps/jellyfin/{config,cache}`, `/data/storage/media` (ro) |
| Immich | `/data/apps/immich/{postgres,model-cache}`, `/data/storage/photos` |
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
| `user: "1000:1500"` | Jellyfin, Vaultwarden |
| 컨테이너 내부 root (생성 파일이 root 소유) | Dockge, Uptime Kuma, Immich, AdGuard Home |

- linuxserver 계열처럼 PUID/PGID를 지원하는 이미지만 환경변수로 지정하고, 그 외에는 `user`로 지정함

---

# 환경변수 (.env)

| 앱 | 변수 | 설명 |
| --- | --- | --- |
| dockge | `STACKS_DIR` | stacks 경로 절대경로. 컨테이너 안팎 경로를 같게 마운트함 |
| homepage | `HOMEPAGE_ALLOWED_HOSTS` | 접속 주소(`host:port`) 목록. LAN IP, Tailscale IP, MagicDNS 이름을 쉼표로 구분 |
| jellyfin | `RENDER_GID` | 서버 render 그룹 GID (`getent group render \| cut -d: -f3`) |
| immich | `UPLOAD_LOCATION` | 사진 저장 위치 (`/data/storage/photos`) |
| immich | `DB_DATA_LOCATION` | Immich Postgres 데이터 위치 (`/data/apps/immich/postgres`) |
| immich | `IMMICH_VERSION` | Immich 버전 (`v3.3.5`) |
| immich | `DB_PASSWORD` | Immich Postgres 비밀번호. A-Za-z0-9만 사용 |
| vaultwarden | `DOMAIN` | tailscale serve 주소, 포트까지 포함 |
| vaultwarden | `SIGNUPS_ALLOWED` | 본인 계정 생성 후 `false` |
| vaultwarden | `ADMIN_TOKEN` | `/admin` 토큰의 argon2 해시. 작은따옴표로 감쌈 |

---

# 배포 방법

1. 서버의 `/data/dev/choimory/repo/`에 저장소 clone
2. 앱 디렉토리에서 `.env.example`을 복사해 `.env` 작성
3. compose 상단 주석의 사전 준비 명령 실행
   - bind mount 경로가 없으면 Docker가 root 소유로 디렉토리를 만들어, `user`로 실행하는 컨테이너가 권한 오류로 실패함
   ```bash
   mkdir -p /data/apps/<앱>/...
   ```
4. `docker compose config`로 확인 후 `docker compose up -d`, 또는 Dockge 화면에서 기동
5. 필요한 앱은 `tailscale serve` 등록

권장 기동 순서: Dockge → Homepage, Uptime Kuma → Jellyfin → Immich, Samba → Vaultwarden, AdGuard Home

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
- 미디어는 읽기 전용 마운트. 메타데이터, 썸네일, 트릭플레이 이미지는 `/config`에 저장
- 아래 설정은 compose가 아니라 Jellyfin 관리 화면에서 한 것이라, 재설치 시 같은 값으로 다시 설정함 (`/data/apps/jellyfin/config`를 복원하면 유지됨)

### GPU 확인

```bash
# 서버의 GPU 장치와 render 그룹 GID 확인 (GID는 .env의 RENDER_GID)
ls -l /dev/dri
getent group render | cut -d: -f3

# 컨테이너 안에서 VA-API로 GPU를 읽을 수 있는지 확인 (AMD Radeon 680M과 지원 코덱 목록이 나오면 성공)
docker exec -it jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128
```

| 코덱 | 하드웨어 디코딩 | 하드웨어 인코딩 |
| --- | --- | --- |
| H.264 | O | O |
| HEVC 8bit / 10bit | O | O |
| VP9 8bit / 10bit | O | X |
| AV1 | O | X |
| MPEG-2, VC-1, VP8 | X | X |

### 관리 화면 설정

| 위치 | 항목 | 값 |
| --- | --- | --- |
| 재생 > 트랜스코딩 | 하드웨어 가속 | `Video Acceleration API (VAAPI)` |
| 재생 > 트랜스코딩 | VA API 장치 | `/dev/dri/renderD128` |
| 재생 > 트랜스코딩 | 하드웨어 디코딩 | `H264`, `HEVC`, `VP9`, `AV1`, `HEVC 10bit`, `VP9 10bit`만 체크 (나머지는 미지원이라 체크하지 않음) |
| 재생 > 트랜스코딩 | 하드웨어 인코딩 활성화 | 체크 |
| 재생 > 트랜스코딩 | Intel 저전력 인코더, VPP 톤 매핑, 톤 매핑 | 끔 (인텔 전용 또는 HDR용) |
| 재생 > 트랜스코딩 | HEVC 하드웨어 인코딩, AV1 인코딩 | 끔 (H.264로 변환. AV1 인코딩은 680M 미지원) |
| 네트워킹 | LAN 네트워크 | `192.168.10.0/24, 100.64.0.0/10` |
| 초기 설정 | 원격 접속 허용 | 체크 |
| 초기 설정 | 메타데이터 언어 / 국가 | Korean / South Korea |

- LAN 네트워크에 Tailscale 대역(`100.64.0.0/10`)을 넣는 이유
  - 비워두면 Jellyfin은 컨테이너 내부 대역(`172.x`)만 LAN으로 보고, Tailscale 기기(`100.x`)는 원격으로 판단해 화질 제한을 걸고 트랜스코딩함
  - `100.64.0.0/10`으로 서버에 닿을 수 있는 건 tailnet 기기뿐이라 LAN으로 취급해도 안전함
  - 대신 밖(LTE 등)에서 볼 때도 원본을 보내려 하므로, 밖에서 쓰는 기기는 재생 화질을 직접 낮춤 (예: `1080p 8~10Mbps`)
- 트랜스코딩 확인 (`h264_vaapi`가 보이면 GPU 인코딩. `libx264`는 로그 앞부분 FFmpeg 빌드 정보에 걸린 것이라 무시)
  ```bash
  docker exec jellyfin sh -c 'ls -t /config/log/FFmpeg.Transcode-* | head -1 | xargs grep -o -m5 -E "h264_vaapi|libx264|hwaccel vaapi"'
  ```

### 라이브러리

| 라이브러리 | 콘텐츠 유형 | 폴더 (컨테이너 경로) |
| --- | --- | --- |
| 게임 | 홈 비디오 및 사진 | `/media/games` |

- 폴더는 서버 경로(`/data/storage/media/...`)가 아니라 컨테이너 경로(`/media/...`)로 지정
- 게임 녹화 영상은 인터넷 영화 DB 검색이 필요 없으므로 홈 비디오 유형 사용 (파일 이름 그대로 표시, 썸네일은 영상에서 추출)
- 하위 폴더는 게임별로 나눔 (`/data/storage/media/games/EternalReturn/` 등). `/data/storage/media` 전체가 마운트돼 있어 새 폴더를 만들어도 compose 수정 불필요
- 옵션: 실시간 모니터링 켬, 트릭플레이 이미지 추출 켬, Nfo 저장과 미디어 폴더에 아트워크·트릭플레이 저장은 끔(읽기 전용), 챕터 이미지 끔

### 재생 화질

- 브라우저 재생기 화질이 `자동`이면 처음 측정한 속도보다 낮게 상한을 잡아, 고비트레이트 원본(게임 녹화 약 100Mbps)도 트랜스코딩됨
- 집에서 쓰는 기기는 프로필 > 설정 > 재생에서 최대 스트리밍 품질을 가장 높은 값으로 저장 → 다이렉트 재생
- 브라우저는 접속 주소(LAN 주소, Tailscale 주소)마다 설정을 따로 저장하므로 주소별로 각각 설정

### 기기별 사용

| 기기 | `accept-routes` | 접속 | 화질 |
| --- | --- | --- | --- |
| 데스크톱 (유선) | false | 브라우저, LAN 또는 Tailscale 주소 | 원본 (다이렉트 재생) |
| 맥북 (와이파이, 외출) | false | 브라우저, Tailscale 주소 | 자동 또는 FHD~2K |
| 아이패드 (와이파이) | 기본값 | 크롬, Tailscale 주소 | FHD~2K |
| 밖 (LTE, 핫스팟) | - | Tailscale 주소 | 1080p 8~10Mbps 이하 |

- 와이파이 기기는 원본(게임 녹화 약 100Mbps)을 꾸준히 받기 버거우므로 화질을 낮춤. 낮추면 서버 GPU가 해상도를 낮춰 변환해 여유 있게 따라감
- iOS 공식 Jellyfin 앱은 iOS 기본 재생기가 녹화 파일(H.264 Level 5.2, 120fps, 100Mbps)을 그대로 못 받아 서버에 원본급 변환을 요청하고, 변환이 실시간을 못 따라가 거의 재생되지 않음 → 크롬으로 사용
- 앱이 필요하면 무료는 Swiftfin, 호환성·편의는 Infuse Pro (Jellyfin 원격 사용은 Pro 필요)
- 근본 해결: 녹화 설정을 1440p 60fps, 30~50Mbps, HEVC로 낮추면 기기별 차이가 대부분 사라짐

## Immich

- 공식 릴리스의 docker-compose.yml을 기준으로 경로와 재시작 정책만 바꿈
- 버전을 올릴 때는 해당 릴리스의 공식 compose와 비교해 redis/database 이미지 변경 여부를 확인하고, 릴리스 노트의 Breaking Changes 확인
- redis(Valkey), postgres는 외부에 포트를 노출하지 않음. postgres 이미지를 다른 것으로 바꾸면 기동하지 않음
- 머신러닝은 CPU로 실행 (ROCm은 이미지가 크고 실험적). 동영상 하드웨어 트랜스코딩이 필요하면 `devices` 주석 해제
- DB는 파일 복사가 아니라 `pg_dump`로 백업
- `DB_PASSWORD`는 첫 `up -d` 전에 정함. DB가 처음 만들어질 때 고정되어, 이후 `.env`만 바꾸면 접속 실패
  ```bash
  # 랜덤 비밀번호(0-9, a-f 48자)를 생성해 .env에 바로 넣기 (Immich는 영문·숫자만 허용)
  sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$(openssl rand -hex 24)/" .env
  ```
- `docker compose config`는 `.env` 값을 그대로 출력하므로 비밀번호가 화면에 노출됨에 주의

### 관리 화면 설정

아래 값은 compose가 아니라 Immich 웹 관리 화면에서 설정한 것으로, DB(`/data/apps/immich/postgres`)에 저장됨

| 위치 | 항목 | 값 |
| --- | --- | --- |
| 첫 설정 | 스토리지 템플릿 | `YYYY/MM/DD` (`library/<레이블>/2026/11/02/...`) |
| 관리 > 사용자 > 편집 | 스토리지 레이블 | `choimory` (기본 `admin`) |
| 관리 > 설정 > 서버 설정 | 외부 도메인 | `http://choimory-server.<tailnet>.ts.net:2283` |
| 관리 > 설정 > 기계 학습 > 스마트 검색 | CLIP 모델 | `nllb-clip-base-siglip__v1` (한국어 포함 다국어. 기본 `ViT-B-32__openai`는 영어 위주) |
| 관리 > 설정 > 기계 학습 | URL | `http://immich-machine-learning:3003` (기본값 유지) |

- 스토리지 템플릿·레이블을 바꾸면 작업 대기열 > 스토리지 템플릿 마이그레이션 실행 (이미 올라간 사진 이동)
- CLIP 모델을 바꾸면 작업 대기열 > 스마트 검색 > 모두 실행 (기존 임베딩과 호환되지 않음)
- 머신러닝 모델은 처음 사용할 때 Hugging Face에서 받아 `/data/apps/immich/model-cache`에 저장. HF_TOKEN 경고는 무시해도 됨
- 모델 로딩 확인
  ```bash
  docker compose logs --tail 40 immich-machine-learning | grep -i -A1 "loading"
  ```

### 아이폰 앱

- 서버 주소는 Tailscale 주소(`http://choimory-server.<tailnet>.ts.net:2283`)로 등록 (집 밖에서도 백업)
- 백업 앨범 `최근 항목`(전체), 모바일 데이터 사용 끔, 백그라운드 백업 켬, 백업 후 기기에서 삭제 끔
- 원본은 아이폰·iCloud에 유지 (외장하드 백업 전까지 Immich를 유일한 사본으로 두지 않음)
- iCloud 저장 공간 최적화 상태여도 앱이 iCloud에서 원본을 받아 원본 화질로 백업. 첫 백업은 와이파이·충전 중 앱 화면을 켜둔 채로 진행해야 빠름
- 백업은 폰 → 서버 한 방향. 사진 앱에서 지운 사진은 Immich에 남고, Immich 앱에서 지울 때 기기 / 서버 / 둘 다를 선택 가능
- 서버가 꺼져 있는 동안 찍은 사진은 복구 후 다음 백업 때 "서버에 없는 사진"으로 잡혀 올라감

## 제외한 앱: File Browser

- 웹 브라우저용 파일 탐색기로 계획했으나 제외함 (2026-11)
- 원작 File Browser는 2026-09-01에 저장소가 아카이브되어 이후 새 버전, 버그 수정, 보안 수정이 없음. 마지막 버전(`v2.63.23`) 이후 공개된 보안 권고는 고쳐지지 않음
- 파일 탐색은 Samba(Finder, 탐색기, iOS 파일 앱)로 충분하므로 별도 웹 탐색기를 두지 않음
- 웹으로 파일을 꺼내거나 링크로 공유해야 할 일이 생기면 유지보수 중인 대체 앱(FileBrowser Quantum 등)을 새로 검토

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
- 공유: `files`(`/data/storage/files`), `media`(`/data/storage/media`). `force group = homeserver`로 컨테이너(`1000:1500`)와 권한을 맞춤
- 맥 호환을 위해 `[global]`에 `fruit` VFS 모듈 적용 (메타데이터를 xattr로 저장, 맥 서버 아이콘)
- 접속: 윈도우 `\\192.168.10.201`, 맥 `smb://choimory-server`, 밖에서는 Tailscale
- 설치, 설정, 접속, 권한, 문제 해결, 가족 계정 추가 방법은 `samba/README.md` 참고

---

# 백업

- 현재 미적용. 서버와 향후 연결할 DAS 외에 다른 저장소가 없어서 보류함
- DAS를 연결할 때 Kopia를 다시 검토함. 저장소를 DAS에 두고 `/data/apps`와 DB 덤프를 백업하는 방식
- 그 전까지 Vaultwarden 볼트는 Bitwarden 앱의 내보내기로 수동 보관함
- 백업 우선순위: Vaultwarden 데이터, Immich DB(`pg_dump`)와 사진, 나머지 `/data/apps`
- Immich는 매일 DB를 자동 덤프해 `/data/storage/photos/backups`에 저장함. 같은 SSD라 SSD 고장 대비는 안 되므로 외장하드 백업 대상에 포함
- 현재 사진 사본은 iCloud 원본 + Immich 서버 두 곳
