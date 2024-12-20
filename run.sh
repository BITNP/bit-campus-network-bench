#/usr/bin/bash
command_exists() {
    command -v "$@" >/dev/null 2>&1
}
if ! command_exists v2ray; then 
    echo "plz install v2ray"
    exit 1
elif [[ ! -f "/usr/share/v2ray/h2y.dat" ]]; then
    echo "plz download h2y.data and copy to /usr/share/v2ray" 
    exit 1
fi

if [[ "$#" -ne 1 ]] || [[ "$1" = "help" ]]; then
    echo "usage $0 {chrome,firefox,chromium}"
    exit 1
fi
if [[ ! $1 = "chrome" ]] && [[ ! $1 = "firefox" ]]; then
    echo "unsupport browser"
    exit 1
fi
cd "$(dirname "$0")"
v2ray -c ./config.json > /dev/null 2>&1 &
v2ray_pid=$!
poetry run python test.py $1
kill $v2ray_pid
