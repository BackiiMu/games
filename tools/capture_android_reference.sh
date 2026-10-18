#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: capture_android_reference.sh screen_name" >&2
    exit 2
fi

case "$1" in
    *[!a-zA-Z0-9_-]*|'')
        echo "screen_name must use letters, numbers, dash or underscore" >&2
        exit 2
        ;;
esac

adb_bin=/Users/backii/Library/Android/sdk/platform-tools/adb
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_dir="$project_dir/reference/android_screens"
remote_path="/sdcard/Download/ef_reference_$1.png"

status=$($adb_bin get-state 2>/dev/null || true)
if [ "$status" != device ]; then
    echo "Android device is not authorized/connected: $status" >&2
    exit 1
fi

foreground=$($adb_bin shell dumpsys activity activities | sed -n -e '/mResumedActivity/p' -e '/topResumedActivity/p' | head -3)
case "$foreground" in
    *com.ekkorr.endlessfrontier*) ;;
    *)
        echo "Original game is not foreground; capture aborted: $foreground" >&2
        exit 1
        ;;
esac

mkdir -p "$output_dir"
$adb_bin shell screencap -p "$remote_path"
$adb_bin pull "$remote_path" "$output_dir/$1.png"
echo "$output_dir/$1.png"
