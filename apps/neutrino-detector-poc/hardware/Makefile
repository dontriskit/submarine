# Makefile — local-first orchestrator for the neutrino-detector-poc fab pipeline.
# Run from this directory.
#
# If kicad-cli is on PATH        → uses local install (fastest).
# Otherwise                       → uses Docker image built from ./Dockerfile
#                                  (no host install needed).
#
# First-time setup if KiCad isn't installed locally:
#   make image           one-off, ~3 min, ~500 MB
# Then any time:
#   make fab             all 5 boards
#   make fab-01          board 01 only
#   make clean           remove fab outputs
#   make shell           interactive shell in the image
#   make info            show which runner will be used

IMAGE := meridian/kicad-fab
TAG   := 9.0.9

# Detect local kicad-cli; otherwise fall back to Docker
HAVE_KICAD := $(shell command -v kicad-cli 2>/dev/null)

ifdef HAVE_KICAD
  RUN := ./make-fab.sh
  RUNNER_LABEL := local kicad-cli ($(HAVE_KICAD))
else
  RUN := docker run --rm -v "$$PWD":/work -w /work $(IMAGE):$(TAG) ./make-fab.sh
  RUNNER_LABEL := docker $(IMAGE):$(TAG)
endif

.DEFAULT_GOAL := help

.PHONY: help info fab fab-01 fab-02 fab-03 fab-04 fab-05 clean image shell

help:
	@echo "Targets:"
	@echo "  make fab           build fab artefacts for all 5 boards"
	@echo "  make fab-01..05    build a single board"
	@echo "  make clean         remove generated fab outputs (keep .gitkeep)"
	@echo "  make image         (re)build the Docker image"
	@echo "  make shell         interactive shell in the image"
	@echo "  make info          show toolchain detection"
	@echo ""
	@echo "Runner: $(RUNNER_LABEL)"

info:
	@echo "Runner:  $(RUNNER_LABEL)"
	@echo "Image:   $(IMAGE):$(TAG)"

fab:
	$(RUN)

fab-01:
	$(RUN) 01
fab-02:
	$(RUN) 02
fab-03:
	$(RUN) 03
fab-04:
	$(RUN) 04
fab-05:
	$(RUN) 05

clean:
	@for d in */fab; do \
	  find "$$d" -mindepth 1 ! -name '.gitkeep' -delete 2>/dev/null || true; \
	done
	@rm -f */*-fab.zip
	@echo "fab outputs cleaned"

image:
	docker build -t $(IMAGE):$(TAG) -t $(IMAGE):latest .

shell:
	docker run --rm -it -v "$$PWD":/work -w /work $(IMAGE):$(TAG) /bin/bash
