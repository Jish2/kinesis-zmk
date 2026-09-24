#!/usr/bin/env bash
#
# Capture the USB console log from a `debug` firmware build
# (bin/build-local.sh debug → flash with bin/flash.sh --local debug).
#
# usage: bin/keylog.sh [-d /dev/tty.usbmodemXXX] [-o FILE]
#
# Records every key event and hold-tap decision, timestamped with firmware
# uptime, to a timestamped keylog-*.txt file. Stop with Ctrl-C.
#
# ⚠ This is a keylogger on yourself: the log contains everything typed
# during the session (passwords included). Keep it local (gitignored)
# and delete it after analysis.

set -euo pipefail

DEV=""
OUT="keylog-$(date +%Y%m%d-%H%M%S).txt"
while [ $# -gt 0 ]; do
  case "$1" in
    -d) DEV="$2"; shift 2 ;;
    -o) OUT="$2"; shift 2 ;;
    *)
      echo "usage: bin/keylog.sh [-d /dev/tty.usbmodemXXX] [-o FILE]" >&2
      exit 2
      ;;
  esac
done

if [ -z "$DEV" ]; then
  # newest usbmodem device (a debug keyboard exposes a CDC ACM port)
  DEV=$(ls -t /dev/tty.usbmodem* 2>/dev/null | head -n 1 || true)
fi
if [ -z "$DEV" ] || [ ! -e "$DEV" ]; then
  echo "error: no /dev/tty.usbmodem* found" >&2
  echo "  is the debug firmware flashed (bin/flash.sh --local debug) and" >&2
  echo "  the keyboard connected over USB?" >&2
  exit 1
fi

echo "capturing $DEV → $OUT (Ctrl-C to stop)"
stty -f "$DEV" 115200 2>/dev/null || stty -F "$DEV" 115200 2>/dev/null || true

trap 'echo; echo "saved → $OUT"; exit 0' INT
cat "$DEV" | tee "$OUT"
