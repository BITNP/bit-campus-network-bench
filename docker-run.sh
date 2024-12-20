#/usr/bin/bash
cd "$(dirname "$0")"
v2ray -c ./config.json > /dev/null 2>&1 &
v2ray_pid=$!
python test.py firefox
kill $v2ray_pid
