# Reproducible KiCad fab-build container for the neutrino-detector-poc.
#
# Build (≈3 min, ≈500 MB image):
#   docker build -t meridian/kicad-fab:9.0.9 .
# or via the Makefile in this directory:
#   make image
#
# Run is automated by the Makefile (`make fab`); see Makefile for direct
# `docker run` invocation if you prefer.
#
# Multi-arch: this Dockerfile builds natively on whatever host you're on
# (amd64 or arm64). The KiCad PPA ships both — no buildx / qemu setup needed
# for typical local use.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# zip → bundling fab outputs; software-properties-common → add-apt-repository
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      ca-certificates \
      zip && \
    add-apt-repository -y ppa:kicad/kicad-9.0-releases && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends kicad && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build-time sanity check — fails the image build if kicad-cli is broken
RUN kicad-cli --version

WORKDIR /work
CMD ["/bin/bash"]
