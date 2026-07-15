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

ARG ALPINE_VERSION="3.23"

FROM scratch AS bin

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS releaser
RUN apk add --no-cache bash findutils
WORKDIR /out
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=from=bin,source=.,target=/release <<EOT
  set -e
  for f in /release/*; do
    if [ ! -d "${f}" ]; then
      continue
    fi

    # check release matches the target platform
    basedir="${TARGETOS}_${TARGETARCH}${TARGETVARIANT:+_${TARGETVARIANT}}"
    if [ ! -d "${f}/${basedir}" ]; then
      continue
    fi

    # copy release files
    for ff in ${f}/${basedir}/*; do
      if [ ! -d "${ff}" ]; then
        continue
      fi
      pdir=$(find $ff -type d -print | sort -n | tail -1)
      relpdir="${pdir#${f}/${basedir}/}"
      (
        set -x
        mkdir -p "/out/${relpdir}"
        cp "${pdir}"/* "/out/${relpdir}/"
        for package in "${pdir}"/*.deb "${pdir}"/*.rpm "${pdir}"/*.tgz "${pdir}"/*.zip; do
          if [ ! -f "$package" ]; then
            continue
          fi
          package_name="${package##*/}"
          package_name="${package_name%.*}"
          cp ${f}/${basedir}/sbom-build*.json "/out/${relpdir}/${package_name}.sbom.json"
          cp "${f}/${basedir}/provenance.json" "/out/${relpdir}/${package_name}.provenance.json"
          if [ -f "${f}/${basedir}/provenance.sigstore.json" ]; then
            cp "${f}/${basedir}/provenance.sigstore.json" "/out/${relpdir}/${package_name}.sigstore.json"
          fi
        done
      )
    done
  done
  if [ -d "/out" ] && [ -f "/release/metadata.env" ]; then
    cp "/release/metadata.env" "/out/"
  fi
EOT

FROM scratch AS release
COPY --from=releaser /out /
