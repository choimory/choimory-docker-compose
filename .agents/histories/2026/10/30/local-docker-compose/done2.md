# 목차

- [개요](#개요)
- [작업 마무리](#작업-마무리)
  - [작업 요약](#작업-요약)
  - [이전 결과](#이전-결과)
  - [compose 변경](#compose-변경)
  - [README 작성](#readme-작성)
  - [결정 사항](#결정-사항)
  - [남은 일](#남은-일)
  - [변경된 파일](#변경된-파일)

---

# 개요

- done1 이후 이어진 추가 작업(plan2)을 마무리함
- 기존 `docker run` 컨테이너를 내리고 새 compose로 이전 완료 (작업자가 직접 수행)
- Redis ACL 적용, Postgres 이미지 OS 고정, README 상세화
- calendar는 DONE 유지

---

# 작업 마무리

> 다 잘됐다 작업 마무리

## 작업 요약

기존 컨테이너(Postgres, Redis, Elasticsearch)에서 `choimory-local` compose로 이전을 마침. 이전 과정에서 Redis에 계정 인증을 추가하고, Postgres 이미지를 기존과 같은 OS로 고정함. 루트, choimory-local, choimory-server README에 실행 방법과 상세 내용을 작성함

## 이전 결과

- 작업자가 plan2의 순서(중지 → 데이터 복사 → 기존 컨테이너 삭제 → `.env` 작성 → `docker compose up -d`)대로 직접 수행했고 정상 동작 확인
- 원본 `~/DataGripProjects/DockerMount`는 며칠 사용 후 삭제

## compose 변경

| 서비스 | 변경 | 이유 |
| --- | --- | --- |
| redis | ACL 적용 (`default` 계정 끔, `REDIS_USER` 계정에 전체 권한), `.env.example` 신규 | username, password 인증 사용 |
| postgres | `postgres:16.15` → `postgres:16.15-bookworm` | 기본 태그는 trixie 기반이라 glibc가 달라 collation이 바뀜. 기존 데이터(bookworm)와 맞춤 |

## README 작성

- **루트 README.md**
  - `# intro`: docker run 대신 compose로 관리하는 이유, docker run 옵션과의 대응표, 재부팅 후 자동 기동
  - `# choimory-local`: 실행 방법, Redis ACL, Postgres bookworm 고정, Docker Desktop 자동 시작
- **choimory-local/README.md**: 실행 환경, 디렉토리 구조, 서비스 목록, compose 작성 규칙, 환경변수, 실행 방법, 자주 쓰는 명령, 서비스별 참고, compose 존재 의의
- **choimory-server/README.md**: 서버 사양, 앱 목록과 포트, 네트워크 규칙, 데이터 경로, compose 작성 규칙, 환경변수, 배포 방법, 앱별 참고, 백업

## 결정 사항

- **Redis**: username + password(ACL) 방식 사용
- **Elasticsearch**: 기본 계정 `elastic`을 그대로 사용. 계정명은 바꿀 수 없고, 별도 계정(native realm, file realm)은 만들지 않음
- **이전 절차**: 한 번만 하는 작업이라 README에 넣지 않고 task1, plan2, compose 상단 주석에만 남김

## 남은 일

- 원본 데이터(`~/DataGripProjects/DockerMount`) 삭제: 며칠 사용 후 문제없으면 진행
- 루트 README의 `# choimory-server` 섹션이 `choimory-server/README.md`와 겹침. 요약 + 링크로 줄일지는 미정

## 변경된 파일

- `choimory-local/redis/compose.yaml`, `choimory-local/redis/.env.example`
- `choimory-local/postgres/compose.yaml`
- `README.md`, `choimory-local/README.md`, `choimory-server/README.md`
- `.agents/histories/2026/10/30/local-docker-compose/plan2.md`, `done2.md`

---
