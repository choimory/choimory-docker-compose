# 목차

- [개요](#개요)
- [작업 마무리하자](#작업-마무리하자)
  - [작업 요약](#작업-요약)
  - [분석 (plan1~3)](#분석-plan13)
  - [구현 (task1)](#구현-task1)
  - [보류 및 남은 일](#보류-및-남은-일)
  - [변경된 파일](#변경된-파일)

---

# 개요

- choimory-server(홈서버 미니PC)의 개인용 앱 Docker Compose 작성 작업을 마무리함
- 분석은 plan1~3, 구현은 task1에 기록함
- calendar를 DONE으로 변경하고, README.md에 프로젝트 구조와 규칙을 반영함

---

# 작업 마무리하자

> 작업 마무리하자

## 작업 요약

Notion의 홈서버 계획(4차 작업 진행) 중 Docker Compose로 운영하기로 한 개인용 앱들의 compose를 `choimory-server/`에 앱별로 작성함. 서버 테스트는 규칙상 직접 수행하지 않고, 테스트 방법을 task1에 정리함.

## 분석 (plan1~3)

- **plan1**: 범위와 구조, 결정 사항
  - 범위: Docker Compose로 운영하는 개인 앱만. k3s/GitOps 대상은 제외
  - 구조: 앱별 디렉토리 + 저장소는 `/data/dev/repos`에 clone, 데이터는 `/data/apps` 절대경로 bind mount
  - 포트: 관리 화면과 Vaultwarden은 `127.0.0.1` + `tailscale serve`, LAN 기기용 앱은 `0.0.0.0`
  - Samba는 호스트 apt 설치, 웹 파일 접근은 File Browser, 선택 앱(Navidrome, Audiobookshelf, Syncthing)은 제외
  - AdGuard: 스텁 리스너만 끄고 서버 자신은 외부 DNS 사용, 서버는 `--accept-dns=false`, Tailscale 보조 DNS 허용
  - 서버 사양: Ryzen 7 7735HS, Radeon 680M → Jellyfin VA-API 하드웨어 트랜스코딩 적용
  - 실행 계정 규칙: PUID/PGID 지원 이미지는 환경변수, 그 외는 `user: "1000:1500"`
- **plan2**: 백업
  - Kopia를 선택했지만, 서버와 DAS 외 저장소가 없어 보류
- **plan3**: 전체 compose
  - Dockge 스택 관리, `container_name` 충돌, 장애 범위 때문에 루트 compose는 만들지 않음

## 구현 (task1)

| 앱 | 이미지 | 호스트 바인딩 |
| --- | --- | --- |
| Dockge | `louislam/dockge:1.5.0` | 127.0.0.1:5001 |
| Homepage | `ghcr.io/gethomepage/homepage:v2.7.0` | 0.0.0.0:3000 |
| Uptime Kuma | `louislam/uptime-kuma:2.5.8` | 127.0.0.1:3001 |
| Jellyfin | `jellyfin/jellyfin:12.4` | 0.0.0.0:8096 |
| Immich | `immich-server:v3.3.5` 외 3개 | 0.0.0.0:2283 |
| File Browser | `filebrowser/filebrowser:v2.63.23` | 0.0.0.0:8081 |
| Vaultwarden | `vaultwarden/server:1.37.4` | 127.0.0.1:8080 |
| AdGuard Home | `adguard/adguardhome:v0.107.79` | 0.0.0.0:53, 127.0.0.1:3002 |
| Samba | 호스트 apt 설치 (`samba/README.md`) | 445 |

- 각 compose 상단 주석에 접속 방법, 사전 준비 명령, 최초 설정 방법을 기록
- 비밀번호, 토큰, 서버별 값은 `.env.example`로 분리하고 `.gitignore`에 `.env` 추가

## 보류 및 남은 일

- **서버 테스트**: 아직 수행하지 않음. task1의 테스트 방법대로 서버에서 확인 필요
- **백업**: DAS 연결 시 Kopia 재검토. 그 전까지 Vaultwarden 볼트 수동 내보내기
- **일괄 기동 스크립트**(`up-all.sh`, `down-all.sh`): 필요해지면 추가
- **Homepage 컨테이너 상태 표시**: 필요해지면 docker-socket-proxy 추가

## 변경된 파일

- `choimory-server/*/compose.yaml`, `choimory-server/*/.env.example`
- `choimory-server/samba/README.md`
- `.gitignore`
- `README.md`
- `.agents/histories/calendar.md`
- `.agents/histories/2026/10/30/choimory-server-docker-compose/plan1~3.md`, `task1.md`, `done1.md`

---
