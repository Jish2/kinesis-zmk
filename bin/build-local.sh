#!/usr/bin/env bash
#
# Build firmware locally in Docker — the same result as the GitHub Actions
# jobs in .github/workflows/build.yml, without the push/CI round-trip.
#
# usage: bin/build-local.sh [clique|no-clique] [--left-only]
#
#   clique    left half with ZMK Studio over USB (works with the Clique
#             web editor) — same as the CI "Build (Clique)" job
#   no-clique plain left build — same as the CI "Build (Legacy)" job
#
# Output: firmware/<timestamp>-<commit>-{left,right}-<variant>.uf2
# Flash the newest local build with: bin/flash.sh --local

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT"

VARIANT="clique"
LEFT_ONLY=false
for arg in "$@"; do
  case "$arg" in
    clique|no-clique) VARIANT="$arg" ;;
    --left-only) LEFT_ONLY=true ;;
    *)
      echo "usage: bin/build-local.sh [clique|no-clique] [--left-only]" >&2
      exit 2
      ;;
  esac
done

case "$VARIANT" in
  clique) SUFFIX="clique" ;;
  no-clique) SUFFIX="noclique" ;;
esac

DOCKER=$(command -v podman || command -v docker)
TIMESTAMP=$(date -u +"%Y%m%d%H%M")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo xxxxxx)

# Version macro (typed by Mod+V): date-branch-commit[-clique], matching CI's
# stamps. No arg → the stamp ends with "." exactly like the CI no-clique job.
if [ "$VARIANT" = "clique" ]; then
  bin/get_version_local.sh clique >/dev/null
else
  bin/get_version_local.sh >/dev/null
fi
restore_version() { git checkout -- config/version.dtsi 2>/dev/null || true; }
trap restore_version EXIT

# -it only when a human is at a terminal; safe from scripts and agents.
TTY_FLAG=""
[ -t 0 ] && TTY_FLAG="-it" || true

# SELinux volume relabeling on Linux (mirrors the old Makefile logic).
Z1=""; Z2=""
if [ "$(uname)" != "Darwin" ]; then
  Z1=":z"; Z2=",z"
fi

echo "==> docker image (cached when unchanged)"
"$DOCKER" build --tag zmk --file Dockerfile .
"$DOCKER" rm -f zmk >/dev/null 2>&1 || true

echo "==> building $VARIANT firmware (commit $COMMIT)"
"$DOCKER" run --rm $TTY_FLAG --name zmk \
  -v "$REPO_ROOT/firmware:/app/firmware$Z1" \
  -v "$REPO_ROOT/config:/app/config:ro$Z2" \
  -e TIMESTAMP="$TIMESTAMP" \
  -e COMMIT="$COMMIT" \
  -e VARIANT="$VARIANT" \
  -e BUILD_RIGHT="$([ "$LEFT_ONLY" = false ] && echo true || echo false)" \
  zmk

echo
echo "✓ local $VARIANT build done:"
ls -1t firmware/*-${SUFFIX}.uf2 2>/dev/null | head -n 2 || true
echo
echo "  flash it with: bin/flash.sh --local $VARIANT"
