# Samba

- 맥·윈도우 네트워크 드라이브용 파일 공유
- 445 포트, 호스트 계정·권한과 엮여 있어 컨테이너가 아닌 호스트에 apt로 설치한다.
- 보안 업데이트는 unattended-upgrades로 자동 적용된다.
- 이 디렉토리는 compose 스택이 아니라 설정 기록용이다.

---

# 설치

```bash
sudo apt install samba

# Samba 비밀번호는 리눅스 계정 비밀번호와 별도로 관리한다.
sudo smbpasswd -a choimory
```

---

# 설정

`/etc/samba/smb.conf` 맨 아래에 추가한다.

```ini
# 개인 문서 공유 (File Browser와 같은 디렉토리)
[files]
   path = /data/nas/files
   valid users = choimory
   read only = no
   # 새 파일도 homeserver 그룹으로 생성해, 컨테이너(1000:1500)와 권한을 맞춘다.
   force group = homeserver
   create mask = 0664
   directory mask = 2775

# 미디어 공유 (Jellyfin 라이브러리에 영상 추가용)
[media]
   path = /data/nas/media
   valid users = choimory
   read only = no
   force group = homeserver
   create mask = 0664
   directory mask = 2775
```

- `/data/nas/photos`는 Immich가 관리하므로 공유하지 않는다. 여기서 파일을 지우거나 옮기면 Immich 데이터가 깨진다.

```bash
# 설정 문법 검사 후 재시작
testparm
sudo systemctl restart smbd
```

---

# 접속

- 맥: Finder > 이동 > 서버에 연결 > `smb://<서버 IP>/files`
- 밖에서는 Tailscale을 켜고 Tailscale IP로 접속한다.

---

# 가족 공유 시

- 로그인 불가 전용 계정을 만들고 Samba 비밀번호만 부여한다.

```bash
sudo useradd -M -s /usr/sbin/nologin 계정명
sudo usermod -aG homeserver 계정명
sudo smbpasswd -a 계정명
```
