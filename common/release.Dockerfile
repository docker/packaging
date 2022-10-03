# syntax=docker/dockerfile:1

# Copyright 2022 Docker Packaging authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG ALPINE_VERSION="3.16"

FROM scratch AS bin-folder

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS releaser
RUN apk add --no-cache bash
WORKDIR /out
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=from=bin-folder,source=.,target=/release <<EOT
  set -e
  for f in /release/*; do
    pkgtype=$(basename $f)
    if [ "$pkgtype" = "static" ]; then
      basedir="${TARGETOS}/${TARGETARCH}"
      if [ -n "$TARGETVARIANT" ]; then
        basedir="${basedir}/${TARGETVARIANT}"
      fi
      [ ! -d "${f}/${basedir}" ] && continue
      (
        set -x
        mkdir -p "/out/static/${basedir}"
        cp "${f}/${basedir}"/* "/out/static/${basedir}/"
      )
    else
      [ "${TARGETOS}" != "linux" ] && continue
      for ff in ${f}/*; do
        pkgrelease=$(basename $ff)
        basedir="${TARGETARCH}"
        if [ -n "$TARGETVARIANT" ]; then
          basedir="${basedir}/${TARGETVARIANT}"
        fi
        [ ! -d "${ff}/${basedir}" ] && continue
        (
          set -x
          mkdir -p "/out/${pkgtype}/${pkgrelease}/${basedir}"
          cp "${ff}/${basedir}"/* "/out/${pkgtype}/${pkgrelease}/${basedir}/"
        )
      done
    fi
  done
  if [ -d "/out" ] && [ -f "/release/metadata.env" ]; then
    cp "/release/metadata.env" "/out/"
  fi
EOT

FROM scratch AS release
COPY --from=releaser /out /
