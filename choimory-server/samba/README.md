# 목차

- [Samba](#samba)
- [설치](#설치)
- [설정](#설정)
  - [공유 폴더](#공유-폴더)
  - [맥 호환 (fruit)](#맥-호환-fruit)
  - [적용과 확인](#적용과-확인)
- [방화벽](#방화벽)
- [접속](#접속)
  - [윈도우](#윈도우)
  - [맥](#맥)
  - [아이폰·아이패드](#아이폰아이패드)
  - [밖에서 접속](#밖에서-접속)
- [권한](#권한)
- [문제 해결](#문제-해결)
- [가족 공유 시](#가족-공유-시)

---

# Samba

- 맥·윈도우 네트워크 드라이브용 파일 공유
- 445 포트, 호스트 계정·권한과 엮여 있어 컨테이너가 아닌 호스트에 apt로 설치한다.
- 보안 업데이트는 unattended-upgrades로 자동 적용된다.
- 이 디렉토리는 compose 스택이 아니라 설정 기록용이다.
- 웹 파일 탐색기(File Browser)는 두지 않고, 파일 탐색은 Samba(Finder, 탐색기, 파일 앱)로 한다.

---

# 설치

```bash
# Samba 설치
sudo apt install samba

# Samba 접속용 비밀번호 등록 (리눅스 로그인 비밀번호와 별도로 관리된다)
sudo smbpasswd -a choimory

# 서비스 상태 확인 (active (running)이면 정상)
systemctl status smbd --no-pager
```

---

# 설정

## 공유 폴더

`/etc/samba/smb.conf` 맨 아래에 추가한다.

```ini
# 개인 문서 공유
[files]
   path = /data/storage/files
   valid users = choimory
   read only = no
   # 새 파일도 homeserver 그룹으로 생성해, 컨테이너(1000:1500)와 권한을 맞춘다.
   force group = homeserver
   create mask = 0664
   directory mask = 2775

# 미디어 공유 (Jellyfin 라이브러리에 영상 추가용)
[media]
   path = /data/storage/media
   valid users = choimory
   read only = no
   force group = homeserver
   create mask = 0664
   directory mask = 2775
```

- `/data/storage` 전체가 아니라 `files`, `media`만 공유한다. 공유 이름으로 등록한 폴더만 접속 시 보인다.
- `/data/storage/photos`는 Immich가 관리하므로 공유하지 않는다. 여기서 파일을 지우거나 옮기면 Immich 데이터가 깨진다.
- `/data/storage/downloads`는 아직 쓰는 앱이 없어 공유하지 않는다. 필요해지면 같은 형식으로 추가한다.

## 맥 호환 (fruit)

- `fruit`는 맥이 SMB로 붙을 때 쓰는 확장(Apple SMB2 extensions)을 Samba가 이해하게 해주는 VFS 모듈이다.
- 맥의 메타데이터(태그, Finder 정보, 리소스 포크)를 파일 옆 `._파일명` 대신 확장 속성(xattr)에 저장해 서버가 깔끔해진다.
- 맥에서 서버 아이콘이 윈도우 PC 모양에서 맥 모양으로 바뀐다. (`fruit:model`)
- Time Machine 공유를 만들 때도 필요하다.

`/etc/samba/smb.conf`의 `[global]` 바로 아래에 추가한다. `[global]`에 넣어야 모든 공유에 적용된다.

```ini
[global]
   vfs objects = fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
```

| 옵션 | 의미 |
|------|------|
| `vfs objects = fruit streams_xattr` | fruit 모듈과, 대체 데이터 스트림을 xattr에 저장하는 모듈을 함께 켠다 |
| `fruit:metadata = stream` | 맥 메타데이터를 스트림(xattr)으로 저장한다 |
| `fruit:model` | 맥 Finder에 보일 서버 아이콘. `MacSamba`(기본), `MacPro`, `Xserve`, `RackMac` 등 |

```bash
# fruit, streams_xattr 모듈이 설치돼 있는지 확인 (Ubuntu samba 패키지에 기본 포함)
ls /usr/lib/x86_64-linux-gnu/samba/vfs/ | grep -E 'fruit|streams_xattr'

# 수정 전 설정 백업
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.before-fruit

# [global] 바로 아래에 세 줄 삽입
sudo sed -i '/^\[global\]/a\   vfs objects = fruit streams_xattr\n   fruit:metadata = stream\n   fruit:model = MacSamba' /etc/samba/smb.conf

# 삽입 결과 확인
grep -n -A4 '^\[global\]' /etc/samba/smb.conf
```

되돌릴 때:

```bash
# 백업본으로 복원하고 재시작
sudo cp /etc/samba/smb.conf.before-fruit /etc/samba/smb.conf
sudo systemctl restart smbd
```

## 적용과 확인

```bash
# 설정 문법 검사 (Loaded services file OK가 나오면 정상, Weak crypto 안내는 무시)
testparm -s > /dev/null

# 설정 적용
sudo systemctl restart smbd

# 재시작 후 상태 확인
systemctl status smbd --no-pager
```

- `testparm -s > /dev/null`인데도 몇 줄이 보이는 건 안내 메시지가 stderr로 나오기 때문이며 정상이다.

---

# 방화벽

- Samba는 호스트 서비스라 ufw 영향을 받는다. (Docker 컨테이너 포트는 ufw를 우회하는 것과 다름)
- 현재 ufw는 비활성 상태라 별도 설정이 없다.
- ufw를 켤 때는 LAN과 Tailscale 대역만 허용한다.

```bash
# ufw 상태 확인
sudo ufw status

# (ufw를 켤 경우) 집 LAN에서만 Samba 허용
sudo ufw allow from 192.168.10.0/24 to any app Samba

# (ufw를 켤 경우) Tailscale 대역에서 Samba 허용
sudo ufw allow from 100.64.0.0/10 to any app Samba
```

---

# 접속

## 윈도우

- 파일 탐색기 주소창에 `\\192.168.10.201` 입력 → 계정 `choimory`, Samba 비밀번호로 로그인
- `files`, `media` 두 개만 보이는 것이 정상이다.
- 자주 쓰면 공유 폴더 우클릭 → 네트워크 드라이브 연결로 드라이브 문자를 붙인다.

## 맥

- Finder → `⌘K`(서버에 연결) → `smb://choimory-server` 또는 `smb://192.168.10.201`
- 공유 선택 창에서 `files`, `media`를 고르면 마운트된다.
- 즐겨 쓰면 서버에 연결 창의 `+`로 즐겨찾는 서버에 등록한다.

## 아이폰·아이패드

- 파일 앱 → 우측 상단 `…` → 서버에 연결 → `smb://192.168.10.201`
- 등록 사용자 → `choimory`, Samba 비밀번호

## 밖에서 접속

- Tailscale을 켜고 `smb://choimory-server`(MagicDNS) 또는 Tailscale IP로 접속한다.
- 445 포트를 공유기에서 포트포워딩하지 않는다.

---

# 권한

- `force group = homeserver`와 `directory mask = 2775`로, Samba로 만든 파일·폴더도 `choimory:homeserver` 소유가 된다.
- 그래서 컨테이너(`1000:1500`)와 Samba가 같은 파일을 서로 읽고 쓸 수 있다.
- Samba로 만든 폴더는 `drwxrwsr-x` 뒤에 `+`가 붙을 수 있다. Samba가 윈도우 권한(NT ACL)을 리눅스 ACL로 저장했다는 표시다.

```bash
# Samba로 만든 폴더 권한 확인 (s = setgid, + = ACL 있음)
ls -l /data/storage/media

# ACL 내용 확인 (mask에 w가 있으면 그룹 쓰기 정상)
getfacl /data/storage/media/폴더명
```

- `mask::r-x`처럼 그룹 쓰기가 막혀 컨테이너가 못 쓰는 문제가 생기면, 각 공유에 `nt acl support = no`를 넣어 ACL 저장을 끈다.

---

# 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| 맥 바탕화면·Finder에서 볼륨이 회색으로 선택 안 됨 | 같은 공유가 중복 마운트됨 | 해당 볼륨 모두 꺼내기(⏏) 후 다시 연결 |
| 맥 사이드바 위치에 서버가 안 보임 | Finder 표시 캐시 | Finder 재실행 (Option + Dock의 Finder 우클릭 → 다시 실행) |
| fruit 적용 후 서버 아이콘이 그대로 | Finder 아이콘 캐시 | 꺼내기 후 재연결, 그래도 그대로면 Finder 재실행 |
| 마운트된 볼륨 이름을 못 바꿈 | 공유 이름은 서버 `smb.conf`의 `[공유명]`이 결정 | 서버에서 `[공유명]`을 바꾸고 `smbd` 재시작 |
| 접속 시 로그인 실패 | Samba 비밀번호 미등록 또는 리눅스 비밀번호 입력 | `sudo smbpasswd -a choimory`로 재등록 |

```bash
# 현재 접속 중인 클라이언트와 열린 파일 확인
sudo smbstatus

# Samba 로그 확인
sudo journalctl -u smbd -n 50 --no-pager
```

---

# 가족 공유 시

- 로그인 불가 전용 계정을 만들고 Samba 비밀번호만 부여한다.

```bash
# 홈 디렉토리 없이, 쉘 로그인 불가 계정 생성
sudo useradd -M -s /usr/sbin/nologin 계정명

# homeserver 그룹에 추가 (공유 폴더 쓰기 권한)
sudo usermod -aG homeserver 계정명

# Samba 비밀번호 등록
sudo smbpasswd -a 계정명
```

- 공유의 `valid users`에 계정을 추가하고(`valid users = choimory 계정명`) `smbd`를 재시작한다.
