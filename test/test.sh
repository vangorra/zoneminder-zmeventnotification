#!/usr/bin/env bash
set -euo pipefail
SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo ""
echo "Starting supervisor."
supervisord --nodaemon --configuration /etc/supervisor/supervisor.conf &

echo ""
echo "Waiting 20 seconds for everything to finish starting."
sleep 20

echo ""
echo "Testing zoneminder is responsive."
curl --fail http://localhost/zm/

echo ""
echo "Testing zm_detect works."
/zmeventnotification/hook/zm_detect.py \
  --config /etc/zm/zmeventnotification.ini \
  --file "$SELF_DIR/snapshot.jpg" \
  --output-path "$SELF_DIR" | grep "detected:car"

echo ""
echo "Testing mlapi works."
echo "Getting access token."
RAW_RESULT=$(curl -H "Content-Type:application/json" -XPOST -d '{"username":"local", "password":"localpass"}' "http://localhost:5000/api/v1/login")
echo "$RAW_RESULT"
ACCESS_TOKEN=$(echo "$RAW_RESULT" | jq -r '.access_token')

echo "Detecting..."
RAW_RESULT=$(curl \
  -XPOST \
  -F"file=@$SELF_DIR/snapshot.jpg" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -v \
  "http://localhost:5000/api/v1/detect/object" \
)
echo "$RAW_RESULT"
echo "$RAW_RESULT" | jq '.[].label' | grep car

echo ""
echo "Stopping zoneminder."
zmpkg.pl stop
echo "Stopping apache."
apachectl -k stop
#echo "Stopping mysql."
#mysqld stop
echo "Stopping supervisord."
supervisorctl stop all

