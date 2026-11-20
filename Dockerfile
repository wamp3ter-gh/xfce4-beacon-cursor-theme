# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Wampeter Foma
#
# Build the themes without installing the tools on this machine.
#
# Usage:
#   rm -rf build && docker build -o build .
#
# Options:
#   - --build-arg BORDER_IN=0.75: inner border width (default 0.5)
#   - --build-arg BORDER_OUT=0.75: outer border width (default 0.5)
#
# What it does:
#   - installs the build tools in a slim Debian image
#   - runs ./build.sh on a copy of the repo
#   - exports only the built themes into build/, owned by you
#
# Why the rm first:
#   - docker build adds to an existing build/ rather than replacing it
FROM debian:stable-slim AS build
RUN apt-get update \
	&& apt-get install -y --no-install-recommends librsvg2-bin x11-apps \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
ARG BORDER_IN=0.5
ARG BORDER_OUT=0.5
RUN BORDER_IN="$BORDER_IN" BORDER_OUT="$BORDER_OUT" ./build.sh

FROM scratch
COPY --from=build /src/build /
