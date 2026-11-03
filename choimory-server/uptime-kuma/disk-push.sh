#!/bin/sh
# 디스크 사용률을 Uptime Kuma Push 모니터로 보고한다.
# Uptime Kuma에는 서버 디스크를 직접 보는 모니터가 없어서, 서버 cron이 사용률을 재서 보낸다.
# 기준 미만이면 up, 이상이면 down으로 보내고, 스크립트가 멈춰 보고가 끊겨도 Push 모니터가 down이 된다.
#
# 사용법
#   disk-push.sh <Push URL> [기준 %, 기본 80] [확인할 경로, 기본 /]
#   Push URL은 Uptime Kuma Push 모니터 화면의 주소에서 ? 앞부분만 넣는다. 토큰이 들어 있으므로 저장소에 커밋하지 않는다.
#
# cron 등록 (choimory 계정 crontab -e, 5분마다)
#   */5 * * * * /data/dev/choimory/repo/choimory-docker-compose/choimory-server/uptime-kuma/disk-push.sh 'http://127.0.0.1:3001/api/push/<토큰>' 80 /
set -eu

PUSH_URL="${1:?사용법: disk-push.sh <Push URL> [기준 %] [경로]}"
THRESHOLD="${2:-80}"
TARGET="${3:-/}"

# Push URL에 ?status=up 같은 쿼리가 붙어 있으면 떼어낸다.
PUSH_URL="${PUSH_URL%%\?*}"

# 사용률(%)에서 숫자만 남긴다.
USAGE=$(df --output=pcent "$TARGET" | tail -n 1 | tr -dc '0-9')

if [ "$USAGE" -lt "$THRESHOLD" ]; then
  STATUS=up
else
  STATUS=down
fi

# Uptime Kuma는 서버 127.0.0.1:3001에 열려 있으므로 서버에서 바로 보낸다.
curl -fsS -m 10 -o /dev/null --get "$PUSH_URL" \
  --data-urlencode "status=$STATUS" \
  --data-urlencode "msg=${TARGET} ${USAGE}% (기준 ${THRESHOLD}%)" \
  --data-urlencode "ping="
