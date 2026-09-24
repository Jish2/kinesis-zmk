DOCKER := $(shell { command -v podman || command -v docker; })

.PHONY: all local left flash flash-local clean_firmware clean_image clean

# Build both halves locally in Docker (clique variant) — no CI round-trip.
# Delegates to bin/build-local.sh, which is also safe to run non-interactively.
all local:
	bin/build-local.sh clique

# Build only the left half (clique variant).
left:
	bin/build-local.sh clique --left-only

# Interactive flash wizard for the GitHub Actions build of the current commit.
flash:
	bin/flash.sh

# Interactive flash wizard for the newest docker-built local firmware
# (offers to build it first via bin/build-local.sh if none exists).
flash-local:
	bin/flash.sh --local

clean_firmware:
	rm -f firmware/*.uf2

clean_image:
	$(DOCKER) image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable

clean: clean_firmware clean_image
