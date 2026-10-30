# 목차

- [개요](#개요)
- [작업시작](#작업시작)
  - [답변](#답변)
  - [작성한 파일](#작성한-파일)
  - [계획에서 더 정한 점](#계획에서-더-정한-점)
  - [이전 및 테스트 방법](#이전-및-테스트-방법)

---

# 개요

- plan1에서 정한 결정 사항을 바탕으로 맥북(Docker Desktop) 로컬 개발용 DB compose를 작성함
- 원하는 것만 골라 띄울 수 있도록 `choimory-local/<서비스>/compose.yaml`로 서비스별 분리
- 이미지 태그는 Docker Hub에서 확인한 버전으로 고정 (2026-10-30 기준)
- 실행 중인 기존 컨테이너를 멈추고 데이터를 옮겨야 해서, 이전과 테스트는 직접 수행하지 않고 방법을 정리해서 전달
- calendar를 TASK로 변경

---

# 작업시작

> 작업시작

## 답변

`choimory-local/` 아래에 DB 4개의 compose 작성을 마침. 아직 아무것도 실행하지 않음. 커밋은 하지 않음

## 작성한 파일

| 서비스 | 파일 | 이미지 | 포트 | 데이터 경로 (`~/choimory_workspace/DataGripProjects/docker_volume/`) |
| --- | --- | --- | --- | --- |
| postgres | compose.yaml, .env.example | `postgres:16.15` | 127.0.0.1:5432 | `postgres` |
| redis | compose.yaml | `redis:8.10.3` | 127.0.0.1:6379 | `redis` |
| elasticsearch | compose.yaml, .env.example | `elasticsearch:8.19.23` | 127.0.0.1:9200 | `elasticsearch` |
| mysql | compose.yaml, .env.example | `mysql:8.4.13` | 127.0.0.1:3306 | `mysql` |

- 공통으로 `restart: always`와 `TZ: Asia/Seoul` 적용
- `container_name`은 기존 이름을 그대로 쓰고, mysql만 `mysql_choimory`를 새로 붙임
- 프로젝트명은 `local-` 접두사를 붙임
- **비밀번호**: `.env.example`에 `# 사용 시 변경` 주석과 `changeme` 자리표시자로 넣음. `.env`는 기존 `.gitignore`로 제외됨
- **ES**: 보안 모드를 켜고 TLS는 끈 구성. 힙은 `ES_HEAP`(기본값 `1g`)으로 정하고, `.env`에 값이 없어도 1g로 뜨게 함

## 계획에서 더 정한 점

- **Postgres와 MySQL 계정 값은 최초 초기화 때만 적용됨**: 기존 Postgres 데이터를 옮기면 `.env`의 `POSTGRES_PASSWORD`와 상관없이 기존 비밀번호가 그대로 유지됨. 헷갈리지 않게 `.env`에 기존 비밀번호를 그대로 넣는 걸 권함
- **Redis는 비밀번호 없이 둠**: `127.0.0.1`에만 열려 있어 외부에서 접근할 수 없음. 기존 익명 볼륨은 `docker rm -v`로 같이 지우도록 주석에 적음

## 이전 및 테스트 방법

각 compose 파일 맨 위 주석에 같은 순서를 적어 둠

1. **기존 컨테이너 중지**
   ```bash
   docker stop postgres_choimory elasticsearch_choimory redis_choimory
   ```
2. **데이터 복사** (이동이 아니라 복사)
   ```bash
   mkdir -p ~/choimory_workspace/DataGripProjects/docker_volume
   cp -Rp ~/DataGripProjects/DockerMount/postgres/data ~/choimory_workspace/DataGripProjects/docker_volume/postgres
   cp -Rp ~/DataGripProjects/DockerMount/elasticsearch/data ~/choimory_workspace/DataGripProjects/docker_volume/elasticsearch
   ```
3. **기존 컨테이너 삭제**
   ```bash
   docker rm postgres_choimory elasticsearch_choimory
   docker rm -v redis_choimory
   ```
4. **각 디렉토리에서 기동**: `cp .env.example .env`로 복사해 값을 바꾼 뒤 실행
   ```bash
   docker compose config
   docker compose up -d
   ```
5. **접속 확인**
   - Postgres와 MySQL: DataGrip 접속
   - ES: `curl -u elastic:<비밀번호> localhost:9200`
   - Redis: `docker exec -it redis_choimory redis-cli ping`
6. **기존 데이터 삭제**: 모두 정상인 걸 확인한 뒤 `~/DataGripProjects/DockerMount` 삭제

ES는 8.19로 한 번 뜨면 8.12로 되돌릴 수 없음. 그래서 6번은 꼭 정상 동작을 확인한 다음에 진행. 앱의 ES 접속 설정에 `elastic` 계정 인증 추가 필요

---
