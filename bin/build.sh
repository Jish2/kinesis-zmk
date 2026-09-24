#!/usr/bin/env bash

set -eu

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date -u +"%Y%m%d%H%M")}"
COMMIT="${COMMIT:-$(echo xxxxxx)}"

# Variant mirrors the two CI jobs in .github/workflows/build.yml:
#   clique    → left half built with ZMK Studio over USB (Clique web editor)
#   no-clique → plain left build, no studio
VARIANT="${VARIANT:-clique}"
case "$VARIANT" in
    clique)    SUFFIX="clique" ;;
    no-clique) SUFFIX="noclique" ;;
    *) echo "VARIANT must be 'clique' or 'no-clique', got '${VARIANT}'" >&2; exit 2 ;;
esac

# West Build (left)
if [ "$VARIANT" = "clique" ]; then
    west build -s zmk/app -p -d build/left -b adv360_left -S studio-rpc-usb-uart -- -DZMK_CONFIG="${PWD}/config" -DCONFIG_ZMK_STUDIO=y
else
    west build -s zmk/app -p -d build/left -b adv360_left -- -DZMK_CONFIG="${PWD}/config"
fi
# Adv360 Left Kconfig file
grep -vE '(^#|^$)' build/left/zephyr/.config
# Rename zmk.uf2
cp build/left/zephyr/zmk.uf2 "./firmware/${TIMESTAMP}-${COMMIT}-left-${SUFFIX}.uf2"

# Build right side if selected
if [ "${BUILD_RIGHT}" = true ]; then
    # West Build (right)
    west build -s zmk/app -p -d build/right -b adv360_right -- -DZMK_CONFIG="${PWD}/config"
    # Adv360 Right Kconfig file
    grep -vE '(^#|^$)' build/right/zephyr/.config
    # Rename zmk.uf2
    cp build/right/zephyr/zmk.uf2 "./firmware/${TIMESTAMP}-${COMMIT}-right-${SUFFIX}.uf2"
fi
