# 목차

- [개요](#개요)
- [plan1 확인](#plan1-확인)
  - [답변](#답변)
  - [Notion 문서 정리](#notion-문서-정리)
  - [진행 계획 (안)](#진행-계획-안)
    - [저장소 구조](#저장소-구조)
    - [서버 반영 방식](#서버-반영-방식)
    - [공통 규칙](#공통-규칙)
    - [작성 순서](#작성-순서)
    - [테스트](#테스트)
  - [결정이 필요한 것](#결정이-필요한-것)
- [추가1](#추가1)
- [추가1 섹션 확인](#추가1-섹션-확인)
  - [답변](#답변-1)
  - [동의하는 부분](#동의하는-부분)
  - [보완이 필요한 부분](#보완이-필요한-부분)
    - [6. AdGuard: 호스트 DNS를 127.0.0.1로 두면 위험](#6-adguard-호스트-dns를-127001로-두면-위험)
    - [관리 화면들의 HTTPS 포트 정리](#관리-화면들의-https-포트-정리)
    - [7. 사양 확인](#7-사양-확인)
  - [확인할 점](#확인할-점)
- [추가2](#추가2)
- [추가2 섹션 확인](#추가2-섹션-확인)
  - [답변](#답변-2)
  - [동의하는 부분](#동의하는-부분-1)
  - [추가로 챙길 점](#추가로-챙길-점)
  - [포트 할당표 초안](#포트-할당표-초안)
- [추가3](#추가3)
- [추가3 섹션 확인](#추가3-섹션-확인)
  - [답변](#답변-3)
  - [사양 확인 결과](#사양-확인-결과)
  - [Jellyfin 반영 내용](#jellyfin-반영-내용)
  - [함께 정할 점](#함께-정할-점)

---

# 개요

- choimory-server 환경에서 사용할 docker compose 구성이 필요함
- choimory-server 디렉토리에 docker compose 파일을 작성해야 함
- 프로젝트 README.md 및 .agents/rules 하위 dev-ops 개발 규칙을 참고해서 진행
- 홈서버에 설치할 어플리케이션들과 계획은 아래 문서에서 확인 
  - https://app.notion.com/p/PC-3fe87e6bf6528071ad2af10621fab4dc?v=20c87e6bf652809ab76f000cf4e368b8&source=copy_link
  - https://app.notion.com/p/4-40887e6bf65280a1ad57c5d72aa19a9b?source=copy_link

---

# plan1 확인

> plan1 확인

## 답변

plan1과 Notion 문서 두 개(홈서버 미니PC 세팅, 4차 작업 진행)를 확인함. 이 저장소의 `choimory-server/`에서 관리할 범위는 Notion ④에서 Docker Compose로 정한 개인용 앱들임.

## Notion 문서 정리

- **범위**: Jellyfin, Immich 같은 개인 앱만 Compose로 올림. 토이프로젝트, 개발용 DB/Redis, Argo CD는 k3s와 GitOps 쪽이라 이 저장소 범위가 아님
- **접속**: Tailscale로만 접속하고 외부에는 공개하지 않음. Jellyfin은 Cloudflare Tunnel로 노출하지 않음
- **디렉토리**: 앱별 데이터는 `/data/apps/<앱>/`, 미디어·사진·파일은 `/data/nas/...`
- **볼륨**: named volume 대신 bind mount 사용
- **실행 계정**: `PUID=1000`(choimory), `PGID=1500`(homeserver)
- **앱 전용 DB**: Immich의 Postgres와 Redis처럼 해당 앱 Compose 안에 두고 외부에 노출하지 않음

## 진행 계획 (안)

### 저장소 구조

앱마다 디렉토리 하나

```txt
choimory-server/
├── dockge/      compose.yaml, .env.example
├── homepage/
├── uptime-kuma/
├── jellyfin/
├── immich/
├── filebrowser/
├── vaultwarden/
└── adguard-home/
```

### 서버 반영 방식

- 저장소를 `/data/dev/repos/`에 clone하고, compose 파일의 bind mount는 절대경로 `/data/apps/<앱>/...`로 지정
  - 코드(Git)와 데이터(`/data/apps`)가 분리되어, `config/` 같은 데이터가 저장소에 섞이지 않음
  - Dockge의 stacks 경로를 저장소의 `choimory-server/`로 지정하면 Dockge에서 바로 관리 가능

### 공통 규칙

- `.env.example`만 커밋하고, 실제 `.env`는 gitignore
- `TZ=Asia/Seoul`, PUID/PGID 공통 적용
- 이미지 태그 고정, `restart: unless-stopped`
- 주석은 dev-ops 주석 규칙을 따름
- 앱별 포트 할당표를 plan에 정리

### 작성 순서

Notion ⑥ 진행 순서와 맞춤

1. Dockge, Homepage, Uptime Kuma
2. Jellyfin (하드웨어 트랜스코딩)
3. Immich, File Browser (+ Samba)
4. Vaultwarden, AdGuard Home
5. 백업 (restic 또는 Kopia)

### 테스트

규칙상 직접 실행하지 않고, 서버에서 검증하는 방법(`docker compose config`, 기동, 접속 확인)을 정리해서 전달

## 결정이 필요한 것

1. **포트 노출**: `0.0.0.0`에 바인딩하고 ufw로 막을지, Tailscale IP(`100.x`)에만 바인딩할지
2. **Samba**: 호스트에 apt로 설치할지, 컨테이너로 띄울지. 호스트에 설치하면 이 저장소에서는 빠짐
3. **웹 파일 접근**: File Browser와 Nextcloud 중 선택. 가벼운 File Browser 추천
4. **선택 앱**: Navidrome, Audiobookshelf, Syncthing을 이번에 포함할지
5. **Vaultwarden**: HTTPS가 필수라 `tailscale serve`나 Tailscale 인증서로 처리할지
6. **AdGuard Home**: 53번 포트가 우분투의 systemd-resolved와 충돌하므로 호스트 설정 변경 필요
7. **미니PC 사양**: Notion에서도 미확인인 CPU/RAM. 인텔 iGPU 여부에 따라 Jellyfin의 `/dev/dri` 설정이 달라짐

---

# 추가1

1. 포트 노출 → 0.0.0.0 바인딩, ufw엔 기대지 않기

먼저 중요한 함정이 하나 있어요. Docker가 공개한 포트는 ufw를 우회해요. Docker가 iptables에 규칙을 직접 넣어서, ufw로 막아도 실제로는 열려 있어요. 그래서 “0.0.0.0 + ufw로 막기”는 생각대로 동작하지 않아요.

그런데 현재 구성에선 0.0.0.0이어도 괜찮아요.

공유기에 포트포워딩이 없으니 인터넷에선 애초에 접근 불가 → 열리는 범위는 집 LAN + Tailscale뿐
집 TV로 Jellyfin 볼 때처럼 Tailscale 없는 기기도 접속 가능

반대로 Tailscale IP에만 바인딩하면, 부팅 시 Docker가 tailscaled보다 먼저 뜨면 주소가 없어서 컨테이너가 안 떠요(systemd 순서 조정 필요). 그리고 TV 같은 기기는 못 붙어요.

예외로 관리 화면(Dockge, AdGuard 관리 페이지 등)이랑 Vaultwarden은 127.0.0.1에만 바인딩하고 tailscale serve로 여는 걸 추천해요(5번이랑 같은 방식).

2. Samba → 호스트에 apt 설치
   Samba는 445 포트, 호스트 계정·권한이랑 엮여 있어서 컨테이너로 띄우면 오히려 복잡해요.
   apt로 깔면 unattended-upgrades로 보안 업데이트도 자동이고요.
   저장소에서 빠지는 건 괜찮아요. smb.conf 내용은 Notion이나 저장소 docs/에 기록만 남겨두면 돼요.
3. 웹 파일 접근 → File Browser 동의

사진은 Immich, 파일 탐색은 Samba가 맡으니 웹은 가끔 쓰는 정도예요. Nextcloud는 캘린더·연락처·오피스까지 쓸 게 아니면 무게 대비 이득이 없어요.

4. 선택 앱 → 이번엔 제외

앱별 폴더 + Compose 구조라 나중에 추가하는 게 폴더 하나 만드는 수준이에요. 핵심 앱 먼저 안정화하고, 실제로 필요해질 때 넣는 게 나아요. 음악을 많이 들으시면 Navidrome 정도만 예외로 고려해볼 만해요.

5. Vaultwarden → tailscale serve

가장 간단해요. 인증서 발급·갱신을 Tailscale이 알아서 해줘요.

bash
tailscale serve --bg --https=8443 http://127.0.0.1:8080
# → https://choimory-server.<tailnet>.ts.net:8443
Tailscale 관리 콘솔 DNS 설정에서 HTTPS Certificates 켜기 필요
발급된 인증서는 공개 인증서 투명성 로그에 기기 이름·tailnet 이름이 남는다는 점만 알고 쓰시면 돼요
아이폰 Bitwarden 앱에서도 Tailscale 켜진 상태면 바로 동작해요
6. AdGuard Home → systemd-resolved 스텁 리스너 끄기

AdGuard 공식 문서에서 안내하는 방법이기도 해요.

bash
sudo mkdir -p /etc/systemd/resolved.conf.d
printf "[Resolve]\nDNS=127.0.0.1\nDNSStubListener=no\n" | sudo tee /etc/systemd/resolved.conf.d/adguardhome.conf
sudo mv /etc/resolv.conf /etc/resolv.conf.backup
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl reload-or-restart systemd-resolved

주의할 점은, AdGuard가 죽으면 그걸 DNS로 쓰는 기기들이 전부 인터넷이 안 돼요. 그래서 처음엔 맥북 하나에서만 DNS로 써보고, 안정되면 Tailscale DNS(전체 기기)에 등록하는 순서를 추천해요. Tailscale 쪽엔 보조 DNS(예: 1.1.1.1)도 같이 넣어두고요.

7. 미니PC 사양 → 직접 확인 필요

서버에서 이것만 돌려서 결과 알려주세요.

bash
lscpu | grep "Model name"
free -h
ls -l /dev/dri

/dev/dri에 renderD128이 보이면 인텔(또는 AMD) iGPU가 잡힌 거라 Jellyfin 하드웨어 트랜스코딩 설정을 넣으면 되고, 없으면 그 설정은 빼면 돼요.

정리하면 1. 0.0.0.0(관리 화면만 127.0.0.1) / 2. 호스트 apt / 3. File Browser / 4. 제외 / 5. tailscale serve / 6. 스텁 리스너 끄기 / 7. 사양 확인 대기예요. 이대로 괜찮으면 4차 문서에 '결정 사항' 섹션으로 반영해 드릴게요.

---

# 추가1 섹션 확인

> 추가1 섹션 확인

## 답변

결론은 대부분 동의함. 다만 6번(AdGuard)은 그대로 적용하면 문제가 생길 수 있어 수정을 권함.

## 동의하는 부분

- **1. 포트 노출**: Docker가 공개한 포트가 ufw를 우회한다는 설명이 맞음. Docker 규칙이 iptables에서 ufw보다 먼저 처리되기 때문. 포트포워딩이 없으니 `0.0.0.0`에 바인딩하고, 관리 화면만 `127.0.0.1` + `tailscale serve`로 여는 구성이 합리적
- **2. Samba를 호스트에 apt로 설치**: 동의. `smb.conf` 기록은 `choimory-server/samba/README.md`처럼 저장소에 남기면 compose 구조와 나란히 관리 가능
- **3. File Browser, 4. 선택 앱 제외**: 둘 다 동의
- **5. Vaultwarden + tailscale serve**: 동의. compose의 `DOMAIN` 환경변수를 `https://choimory-server.<tailnet>.ts.net:8443`처럼 serve 주소와 똑같이 맞춰야 함

## 보완이 필요한 부분

### 6. AdGuard: 호스트 DNS를 127.0.0.1로 두면 위험

문서대로 `DNS=127.0.0.1`을 설정하면 서버 자신도 AdGuard 컨테이너로 DNS를 조회함

- AdGuard가 죽으면 서버의 DNS도 끊김
- 그러면 `docker pull`, `apt`, `tailscale` 같은 복구에 필요한 작업까지 막힘

그래서 `DNSStubListener=no`만 쓰고, 서버 자신은 외부 DNS를 쓰도록 하는 걸 권함

```ini
[Resolve]
DNS=1.1.1.1 8.8.8.8
DNSStubListener=no
```

추가로 확인할 점

- **서버의 Tailscale DNS 설정**: Tailscale DNS를 AdGuard로 지정하면, 서버도 tailnet DNS를 받아 결국 자기 자신을 바라보게 됨. 서버에서는 `tailscale set --accept-dns=false`로 끄는 게 안전
- **Tailscale 보조 DNS(1.1.1.1)**: 가용성은 좋아지지만, 질의가 보조 DNS로 가면 광고 차단이 일부 새어 나감. 차단이 완벽하지 않아도 되는지 결정 필요

### 관리 화면들의 HTTPS 포트 정리

Dockge, AdGuard 관리 화면, Vaultwarden을 모두 `tailscale serve`로 열면, 앱마다 별도의 HTTPS 포트가 필요함

- **경로 방식(`/dockge`)은 비추천**: 대부분의 앱이 하위 경로를 잘 지원하지 않음
- **포트 할당표**: plan에 넣을 포트 할당표에 다음 세 가지를 함께 정리
  - 내부 포트(`127.0.0.1:xxxx`)
  - serve 포트
  - 공개 포트(`0.0.0.0:xxxx`)

### 7. 사양 확인

명령어는 적절함. 결과를 받으면 Jellyfin의 `/dev/dri` 설정 여부를 결정

## 확인할 점

추가1 마지막 줄의 "4차 문서에 '결정 사항' 섹션으로 반영"은 Notion 쪽 이야기로 보임. 이 저장소에서는 plan1에 결정 사항을 정리

---

# 추가2

제가 드린 DNS=127.0.0.1은 AdGuard 공식 문서 예시를 그대로 따른 건데, 서버가 자기 복구 수단(apt, docker pull, tailscale)까지 AdGuard에 의존하게 되는 건 홈서버 한 대 구성에선 확실히 위험해요. 수정안대로 가는 게 맞아요.

몇 가지만 보완할게요.

6. AdGuard 설정

resolved.conf 수정 외에 resolv.conf 심볼릭 링크 교체는 그대로 필요해요. 스텁 리스너를 끄면 기존 /etc/resolv.conf(127.0.0.53을 가리킴)가 죽은 주소가 되거든요.
bash
sudo mkdir -p /etc/systemd/resolved.conf.d
printf "[Resolve]\nDNS=1.1.1.1 8.8.8.8\nDNSStubListener=no\n" | sudo tee /etc/systemd/resolved.conf.d/adguardhome.conf
sudo mv /etc/resolv.conf /etc/resolv.conf.backup
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved
tailscale set --accept-dns=false도 동의해요. 다만 이러면 서버에서 MagicDNS 이름(맥북 등 다른 기기 이름)이 안 풀려요. 서버가 다른 기기를 이름으로 부를 일은 거의 없어서 문제는 없지만, 필요하면 IP로 접근하면 된다는 것만 기록해두세요.
보조 DNS 문제는 생각보다 새는 비율이 클 수 있어요. Tailscale 전역 네임서버를 여러 개 넣으면 "주 → 장애 시 보조"가 아니라 클라이언트가 섞어서 쓸 수 있거든요. 제 의견은 보조 DNS는 넣고 차단이 일부 새는 건 감수하는 쪽이에요. AdGuard 장애 시 Tailscale 켜둔 아이폰·맥북 인터넷이 통째로 끊기는 것보다 광고 몇 개 보이는 게 낫고, Uptime Kuma로 AdGuard 감시 걸어두면 장애도 바로 알 수 있으니까요. 완벽한 차단이 더 중요하면 AdGuard 단독으로 가도 되고요.

5. Vaultwarden DOMAIN

맞아요. 포트까지 정확히 일치해야 웹 볼트, 첨부파일 링크, 패스키가 정상 동작해요.

포트 할당표

경로 방식 비추천에 동의해요.
serve는 tailnet 내부용이라 포트 제한이 없지만, Funnel(인터넷 공개)은 443/8443/10000만 되니 쓰지 않는 걸로 표에 명시해두면 좋아요.
참고로 포트 번호가 거슬리면 앱마다 Tailscale 사이드카 컨테이너를 붙여서 vault.<tailnet>.ts.net처럼 기기 이름을 따로 받는 방식도 있어요. 443 하나로 깔끔해지지만 tailnet에 기기가 늘고 컨테이너도 늘어서, 지금 규모면 포트 할당표 방식이 더 단순해요.
AdGuard는 53번(DNS)은 0.0.0.0, 관리 화면만 127.0.0.1로 나눠서 매핑해야 하니 표에서 행을 두 개로 나누는 게 헷갈리지 않아요.

---

# 추가2 섹션 확인

> 추가2 섹션 확인

## 답변

추가2 내용은 맞고, 이제 정할 것은 거의 다 정해짐. 몇 가지만 보완하면 됨.

## 동의하는 부분

- **resolv.conf 심볼릭 링크 교체**: 맞음. 스텁 리스너를 끄면 기존 `/etc/resolv.conf`가 가리키는 `127.0.0.53`이 응답하지 않으니 링크 교체가 필요함. 추가1 섹션 확인의 수정안에서 빠진 부분
- **`--accept-dns=false`의 부작용**: 서버에서 MagicDNS 이름을 쓸 수 없다는 점은 결정 사항에 기록
- **보조 DNS**: 넣고, 광고 차단이 일부 새는 건 감수하는 쪽에 동의. AdGuard 장애 때 모든 기기의 인터넷이 끊기는 것보다 나음
- **포트 할당표**
  - Funnel은 쓰지 않는다고 표에 명시
  - Tailscale 사이드카 방식은 지금 규모에서는 보류
  - AdGuard는 DNS용과 관리 화면용으로 행을 나눔

## 추가로 챙길 점

- **AdGuard 53번 포트**: TCP와 UDP를 둘 다 매핑해야 함
- **AdGuard 관리 포트**: 첫 설정 마법사는 3000번에서 열리고, 설정이 끝나면 관리 화면이 지정한 포트(기본 80)로 옮겨감. compose에 이 흐름을 주석으로 남김
- **Vaultwarden 보안**
  - 계정을 만든 뒤 `SIGNUPS_ALLOWED=false`로 가입을 막음
  - `ADMIN_TOKEN`은 평문이 아니라 argon2 해시로 넣음
- **Uptime Kuma로 AdGuard 감시**: HTTP가 아니라 DNS 모니터 타입으로 `100.x:53`을 감시해야 실제 DNS 응답 여부를 확인 가능
- **Homepage**: 0.0.0.0으로 열려면 `HOMEPAGE_ALLOWED_HOSTS` 설정 필요

## 포트 할당표 초안

원칙

- 관리 화면은 `127.0.0.1`에만 열고 serve로 접근
- LAN 기기(TV 등)가 써야 하는 앱만 `0.0.0.0`으로 엶
- serve 포트는 호스트 포트와 같은 번호로 맞춤. Vaultwarden만 추가1에서 정한 8443 유지

| 앱 | 컨테이너 포트 | 호스트 바인딩 | tailscale serve (HTTPS) | 비고 |
| --- | --- | --- | --- | --- |
| Dockge | 5001 | 127.0.0.1:5001 | 5001 | 관리 |
| Uptime Kuma | 3001 | 127.0.0.1:3001 | 3001 | 관리 |
| AdGuard (관리) | 80 (첫 설정 3000) | 127.0.0.1:3002 | 3002 | 관리 |
| AdGuard (DNS) | 53/tcp, 53/udp | 0.0.0.0:53 | - | 클라이언트 DNS |
| Vaultwarden | 80 | 127.0.0.1:8080 | 8443 | `DOMAIN` 일치 필수 |
| Homepage | 3000 | 0.0.0.0:3000 | - | |
| Jellyfin | 8096 | 0.0.0.0:8096 | - | TV 접속 |
| Immich | 2283 | 0.0.0.0:2283 | - | 앱 내 로그인 |
| File Browser | 80 | 0.0.0.0:8081 | - | 앱 내 로그인 |
| Samba (호스트) | - | 445 | - | apt 설치, compose 아님 |

- Funnel(인터넷 공개)은 사용하지 않음
- 서버 사양(7번)은 결과 대기 중

---

# 추가3

```shell
choimory@choimory-server:~$ lscpu | grep "Model name"
Model name:                              AMD Ryzen 7 7735HS with Radeon Graphics
choimory@choimory-server:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            26Gi       897Mi        25Gi       1.6Mi       1.1Gi        25Gi
Swap:          8.0Gi          0B       8.0Gi
choimory@choimory-server:~$ ls -l /dev/dri
total 0
drwxr-xr-x 2 root root         80 Oct 24 20:52 by-path
crw-rw---- 1 root video  226,   0 Oct 24 20:52 card0
crw-rw---- 1 root render 226, 128 Oct 24 20:52 renderD128
choimory@choimory-server:~$ 
```

---

# 추가3 섹션 확인

> 추가3 섹션 확인

## 답변

Jellyfin 하드웨어 트랜스코딩을 쓸 수 있는 사양이라 7번은 "설정 포함"으로 결정.

## 사양 확인 결과

- **CPU**: AMD Ryzen 7 7735HS, 8코어 16스레드
  - 내장 그래픽은 Radeon 680M(RDNA2)
  - Notion에서는 인텔을 전제로 했지만, AMD도 VA-API로 하드웨어 트랜스코딩 가능
- **RAM**: 26Gi
  - 32GB 중 일부를 BIOS에서 내장 그래픽 메모리(UMA)로 떼어 준 것으로 보임
  - 계획한 앱 전부와 k3s까지 돌리기에 충분
- **`/dev/dri`**: `renderD128`이 보이므로 GPU가 정상적으로 인식된 상태

## Jellyfin 반영 내용

- **이미지**: 공식 `jellyfin/jellyfin` 사용. 내장된 jellyfin-ffmpeg에 AMD용 VA-API 드라이버(Mesa)가 들어 있음
- **compose 설정**
  - `devices`에 `/dev/dri/renderD128` 매핑
  - `group_add`에 render 그룹 GID 추가. `renderD128`이 `root:render` 소유이기 때문
  - render GID는 서버마다 달라서 `getent group render`로 확인한 뒤 `.env`의 `RENDER_GID`로 넣음
- **Jellyfin 관리 화면**: 하드웨어 가속을 **VA-API**로, 장치를 `/dev/dri/renderD128`로 지정
- **코덱 지원 (680M 기준)**
  - 디코딩: H.264, HEVC, VP9, AV1
  - 인코딩: H.264, HEVC (AV1 인코딩 불가)
- **검증 명령**: 컨테이너가 뜬 뒤 아래 명령으로 지원 코덱 목록이 나오면 정상

  ```bash
  docker exec -it jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128
  ```

## 함께 정할 점

- **PUID/PGID 규칙 보완**: `PUID`/`PGID` 환경변수는 linuxserver 이미지에서만 동작함. 공식 Jellyfin처럼 다른 이미지는 `user: "1000:1500"`으로 실행 계정을 지정해야 함. 이 내용을 공통 규칙에 넣음
- **Immich 머신러닝**: ROCm(AMD GPU 가속)은 이미지가 크고 실험적이라 CPU로 돌리는 걸 권함. 이 CPU면 얼굴 인식이나 검색 인덱싱도 무리 없음
- **Immich 동영상 트랜스코딩**: 같은 `/dev/dri`로 VA-API 사용 가능. 필요해지면 넣는 선택 사항으로 둠

---
