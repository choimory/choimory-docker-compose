# 목차

- [개요](#개요)
- [작업 마무리하자](#작업-마무리하자)
  - [작업 요약](#작업-요약)
  - [분석 (plan1)](#분석-plan1)
  - [구현 (task1)](#구현-task1)
  - [남은 일](#남은-일)
  - [변경된 파일](#변경된-파일)

---

# 개요

- 맥북 로컬 개발용 DB의 Docker Compose 작성 작업을 마무리함
- 분석은 plan1, 구현은 task1에 기록함
- calendar를 DONE으로 변경하고, README.md에 choimory-local 구조와 규칙을 반영함

---

# 작업 마무리하자

> 작업 마무리하자

## 작업 요약

맥북에서 `docker run`으로 15개월째 돌던 Postgres, Redis, Elasticsearch를 compose로 옮기고, MySQL을 새로 추가함. 서비스별로 `choimory-local/<서비스>/compose.yaml`을 작성함. 기존 컨테이너 중지와 데이터 이전은 직접 수행하지 않고, 방법을 task1과 각 compose 주석에 정리함.

## 분석 (plan1)

- **현재 상태 파악**: `docker inspect`로 기존 컨테이너 3개의 이미지, 포트, 데이터 경로, 재시작 정책 확인
  - Redis는 익명 볼륨, 포트는 모두 `0.0.0.0`, ES는 메모리 제한 없음
  - plan1에 들어 있던 비밀번호 평문은 `****`로 마스킹
- **구조**: 원하는 것만 골라 띄울 수 있도록 서비스별 디렉토리로 분리 (한 파일 + profiles 방식 대신)
- **결정 사항**
  - 저장소 위치: `choimory-local/`
  - 데이터 경로: `~/choimory_workspace/DataGripProjects/docker_volume/<서비스>`
  - 포트: `127.0.0.1:기본포트`
  - 버전: Postgres 16.15(메이저 유지), Redis 8.10.3(데이터 버림), ES 8.19.23, MySQL 8.4.13(8 계열 LTS)
  - ES: 보안 모드 활성화(인증만, TLS 비활성), 힙 1g
  - 비밀번호: `.env.example`에 주석과 자리표시자로 두고 사용 시 `.env`로 복사

## 구현 (task1)

| 서비스 | 이미지 | 포트 |
| --- | --- | --- |
| postgres | `postgres:16.15` | 127.0.0.1:5432 |
| redis | `redis:8.10.3` | 127.0.0.1:6379 |
| elasticsearch | `elasticsearch:8.19.23` | 127.0.0.1:9200 |
| mysql | `mysql:8.4.13` | 127.0.0.1:3306 |

- 공통: `restart: always`, `TZ: Asia/Seoul`, 프로젝트명 `local-<서비스>`, 기존 `container_name` 유지
- 각 compose 상단 주석에 기존 컨테이너에서 이전하는 방법을 기록

## 남은 일

- **이전 및 테스트**: 아직 수행하지 않음. task1의 6단계대로 진행 필요
  - ES는 8.19로 한 번 뜨면 8.12로 되돌릴 수 없으므로 반드시 복사로 이전하고, 정상 확인 후 기존 데이터 삭제
- **앱 설정 변경**: ES 보안 모드를 켰으므로 앱의 ES 접속 설정에 `elastic` 계정 인증 추가

## 변경된 파일

- `choimory-local/*/compose.yaml`, `choimory-local/*/.env.example`
- `README.md`
- `.agents/histories/calendar.md`
- `.agents/histories/2026/10/30/local-docker-compose/plan1.md`, `task1.md`, `done1.md`

---
