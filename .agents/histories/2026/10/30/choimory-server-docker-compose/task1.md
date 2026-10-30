# 목차

- [개요](#개요)
- [작업시작](#작업시작)
  - [답변](#답변)
  - [작성한 파일](#작성한-파일)
  - [계획과 다르게 하거나 새로 정한 점](#계획과-다르게-하거나-새로-정한-점)
  - [테스트 방법 (서버에서 직접 실행)](#테스트-방법-서버에서-직접-실행)

---

# 개요

- plan1에서 정한 결정 사항을 바탕으로 choimory-server의 Docker Compose 파일을 작성함
- 앱마다 `choimory-server/<앱>/compose.yaml` 디렉토리 하나씩 구성
- 이미지 태그는 Docker Hub와 GitHub에서 확인한 최신 정식 버전으로 고정 (2026-10-30 기준)
- 규칙상 테스트는 직접 수행하지 않고, 서버에서 검증하는 방법을 정리해서 전달
- calendar를 TASK로 변경

---

# 작업시작

> 작업시작

## 답변

compose 파일 작성을 마침. 아직 아무것도 실행해 보지 않았음. 로컬에는 YAML 파서가 없어 문법 검사도 못 했으므로, 서버에서 아래 테스트 방법으로 확인 필요. 커밋은 하지 않음.

## 작성한 파일

`choimory-server/` 아래에 앱별 디렉토리 생성

| 앱 | 파일 | 이미지 | 바인딩 |
| --- | --- | --- | --- |
| dockge | compose.yaml, .env.example | `louislam/dockge:1.5.0` | 127.0.0.1:5001 |
| homepage | compose.yaml, .env.example | `ghcr.io/gethomepage/homepage:v2.7.0` | 0.0.0.0:3000 |
| uptime-kuma | compose.yaml | `louislam/uptime-kuma:2.5.8` | 127.0.0.1:3001 |
| jellyfin | compose.yaml, .env.example | `jellyfin/jellyfin:12.4` | 0.0.0.0:8096 |
| immich | compose.yaml, .env.example | `immich-server:v3.3.5` 외 3개 | 0.0.0.0:2283 |
| filebrowser | compose.yaml | `filebrowser/filebrowser:v2.63.23` | 0.0.0.0:8081 |
| vaultwarden | compose.yaml, .env.example | `vaultwarden/server:1.37.4` | 127.0.0.1:8080 |
| adguard-home | compose.yaml | `adguard/adguardhome:v0.107.79` | 0.0.0.0:53, 127.0.0.1:3002 |
| samba | README.md | 호스트 apt 설치 | 445 |

- `.gitignore`에 `.env` 추가
- 각 compose 파일 맨 위 주석에 사전 준비 명령(`mkdir`), `tailscale serve` 명령, 최초 설정 방법을 적음

## 계획과 다르게 하거나 새로 정한 점

- **Jellyfin 버전**: 최신 정식 릴리스가 v12.4. 이전 버전이 10.11.x였으니 메이저 버전이 크게 올라간 셈. 새로 설치하는 거라 문제는 없음
- **Homepage**: Docker 소켓을 마운트하지 않음. 대시보드에 컨테이너 상태를 띄우려면 socket proxy가 필요해서, 우선은 링크만 보여주는 대시보드로 둠
- **Immich**: 공식 v3.3.5의 compose 파일을 기준으로 경로와 `restart`만 바꿈. redis와 postgres는 공식 compose에 있는 digest를 그대로 썼고, VA-API 설정은 주석으로만 넣어 둠
- **File Browser**: `/data/nas/files`만 노출. 여기서 photos나 media를 지우거나 옮기면 Immich와 Jellyfin 데이터가 깨질 수 있기 때문. Samba도 같은 이유로 `files`와 `media`만 공유
- **AdGuard**: 처음 설정 마법사에서 관리 웹 포트를 3000 그대로 두어야 포트 매핑이 맞음. compose 주석에 적어 둠
- **root로 실행되는 앱**: Dockge, Uptime Kuma, Immich, AdGuard는 컨테이너 안에서 root로 돌아서 이 앱들이 만드는 파일은 root 소유가 됨. 나머지는 `user: "1000:1500"`이나 PUID/PGID로 choimory:homeserver 계정으로 실행
- **백업**: restic과 Kopia 중 아직 정하지 않아서 이번에는 넣지 않음

## 테스트 방법 (서버에서 직접 실행)

1. 저장소를 `/data/dev/repos/`에 clone
2. 앱마다 `.env.example`을 복사해 `.env`를 만들고 값을 채움
   - jellyfin: `getent group render | cut -d: -f3` 결과를 `RENDER_GID`에 넣음
   - immich: `DB_PASSWORD` 변경
   - vaultwarden: `DOMAIN`과 `ADMIN_TOKEN` 해시 입력
3. compose 주석에 있는 `mkdir` 명령을 먼저 실행
   - 디렉토리 없이 기동하면 Docker가 root 소유로 디렉토리를 만들어서, user로 실행하는 컨테이너가 권한 오류로 실패함
4. 앱 디렉토리에서 순서대로 확인
   - `docker compose config`로 문법과 변수 치환 결과 확인
   - `docker compose up -d` 후 `docker compose ps`, `docker compose logs` 확인
   - 접속 주소로 화면이 뜨는지 확인
5. Jellyfin은 compose 주석에 있는 `vainfo` 명령으로 하드웨어 트랜스코딩 확인
6. AdGuard는 `dig @<Tailscale IP> google.com`으로 DNS 응답 확인

진행 순서는 Notion ⑥과 같게 Dockge → Homepage, Uptime Kuma → Jellyfin → Immich, File Browser, Samba → Vaultwarden, AdGuard를 권함

---
