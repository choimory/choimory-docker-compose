# 목차

- [개요](#개요)
- [어플리케이션별 docker compose말고 어플리케이션 전체 한번에 올리는 도커 컴포즈는 필요 없나?](#어플리케이션별-docker-compose말고-어플리케이션-전체-한번에-올리는-도커-컴포즈는-필요-없나)
  - [답변](#답변)
  - [전체 compose가 없어도 되는 이유](#전체-compose가-없어도-되는-이유)
  - [그래도 한 번에 올리고 싶다면](#그래도-한-번에-올리고-싶다면)
    - [방법 1: 스크립트 (추천)](#방법-1-스크립트-추천)
    - [방법 2: 루트 compose의 include](#방법-2-루트-compose의-include)
  - [정리](#정리)

---

# 개요

- task1에서 앱별 compose(`choimory-server/<앱>/compose.yaml`)를 작성함
- 앱 전체를 한 번에 올리는 compose가 필요한지 검토함
- task1의 앱별 compose 구조와 Dockge 스택 관리 방식을 참고해서 진행

---

# 어플리케이션별 docker compose말고 어플리케이션 전체 한번에 올리는 도커 컴포즈는 필요 없나?

> 어플리케이션별 docker compose말고 어플리케이션 전체 한번에 올리는 도커 컴포즈는 필요 없나?

## 답변

필요 없다고 봄. 앱별 compose만 두는 걸 추천함

## 전체 compose가 없어도 되는 이유

1. **재부팅해도 자동으로 다시 뜸**: 모든 서비스가 `restart: unless-stopped`라서, 한 번 `up -d` 해두면 재부팅 후 Docker가 알아서 다시 띄움. 한 번에 올릴 일은 처음 설치할 때나 전부 `down` 했을 때 정도
2. **Dockge와 충돌함**
   - Dockge는 디렉토리 하나를 스택(compose 프로젝트) 하나로 관리함
   - 전체 compose를 만들면 같은 컨테이너가 두 프로젝트에 속하게 됨. 앱별 프로젝트와 전체 프로젝트
   - `container_name`이 같아서, 한쪽으로 띄운 상태에서 다른 쪽을 올리면 이름 충돌로 실패함
   - 결국 둘 중 하나만 써야 함
3. **앱별로 따로 관리하는 게 안전함**: Immich를 업그레이드하거나 재시작할 때 Vaultwarden이나 AdGuard(DNS)까지 같이 영향받지 않음. 하나로 묶으면 실수로 `docker compose down` 한 번에 DNS까지 전부 내려감

## 그래도 한 번에 올리고 싶다면

### 방법 1: 스크립트 (추천)

`choimory-server/up-all.sh` 같은 스크립트로 앱 디렉토리를 순서대로 돌며 `docker compose up -d` 실행

- 프로젝트는 앱별 그대로라 Dockge와 충돌하지 않음
- 기동 순서도 지정 가능. 예를 들어 AdGuard를 먼저 띄울 수 있음

### 방법 2: 루트 compose의 include

Compose의 `include` 기능으로 앱별 compose를 모아 하나의 프로젝트로 묶음

- 위에서 말한 Dockge 충돌과 이름 충돌 문제가 그대로 생김
- 그래서 이 저장소 구조에서는 비추천

## 정리

- 기본은 지금처럼 앱별 compose + Dockge로 관리
- 일괄 기동이 필요하면 compose가 아니라 스크립트(`up-all.sh`, `down-all.sh`)를 추가
- 스크립트를 추가한다면 기동 순서는 AdGuard → Dockge → 나머지 순서를 제안

---
