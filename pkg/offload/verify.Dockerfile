# syntax=docker/dockerfile:1

# Copyright 2026 Docker Packaging authors
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

# Installs the built package on a clean distro image and checks the plugin it installs.

ARG XX_VERSION="1.10.0"

ARG DISTRO_TYPE="deb"
ARG DISTRO_IMAGE="debian:trixie"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin
FROM scratch AS scripts

FROM ${DISTRO_IMAGE} AS base
# The version the plugin must report, for example v0.7.48. Empty skips the version check.
ARG VERSION=""
ARG PLUGIN=/usr/libexec/docker/cli-plugins/docker-offload

FROM base AS verify-deb
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
ARG VERSION
ARG PLUGIN
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "error: no packages found in $dir"
    exit 1
  fi
  for package in $(find $dir -type f -name '*.deb'); do
    (
      set -x
      dpkg-deb --info $package
      # Check the package contents, not the installed files, as some base images exclude /usr/share/doc.
      dpkg-deb --contents $package | grep -E ' \./usr/share/doc/docker-offload-plugin/LICENSE$'
      dpkg-deb --contents $package | grep -E ' \./usr/share/doc/docker-offload-plugin/THIRD-PARTY-NOTICES$'
      apt-get update
      apt-get install -y --no-install-recommends $package
    )
  done
  set -x
  test -x "$PLUGIN"
  "$PLUGIN" docker-cli-plugin-metadata
  if [ -n "$VERSION" ]; then
    "$PLUGIN" docker-cli-plugin-metadata | grep -F "\"Version\": \"$VERSION\""
  fi
EOT

FROM base AS verify-rpm
COPY --from=xx / /
ARG DISTRO_NAME
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
RUN --mount=type=bind,from=scripts,source=verify-rpm-init.sh,target=/usr/local/bin/verify-rpm-init \
  verify-rpm-init $DISTRO_NAME
ARG TARGETPLATFORM
ARG VERSION
ARG PLUGIN
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "error: no packages found in $dir"
    exit 1
  fi
  for package in $(find $dir -type f -name '*.rpm' ! -name '*.src.rpm'); do
    (
      set -x
      rpm -qilp $package
      rpm -qLp $package | grep -E '/docker-offload-plugin/LICENSE$'
      rpm -qLp $package | grep -E '/docker-offload-plugin/THIRD-PARTY-NOTICES$'
      dnf install -y $package
    )
  done
  set -x
  test -x "$PLUGIN"
  "$PLUGIN" docker-cli-plugin-metadata
  if [ -n "$VERSION" ]; then
    "$PLUGIN" docker-cli-plugin-metadata | grep -F "\"Version\": \"$VERSION\""
  fi
EOT

# The darwin and windows binaries cannot run in this Linux container, so check each archive:
# checksum, layout, and that the binary matches the platform in its path and holds the version.
# Only an archive whose platform equals the container's platform (linux) also runs the plugin and
# checks the version from its metadata; the others check the version as a string in the binary.
# Signatures are not checked.
FROM base AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends file tar unzip
COPY --from=xx / /
ARG TARGETPLATFORM
ARG VERSION
RUN --mount=from=bin,target=/build <<EOT
  set -e
  packages=$(find /build -type f \( -name '*.tgz' -o -name '*.zip' \) | sort)
  if [ -z "$packages" ]; then
    echo >&2 "error: no static archives found in /build"
    exit 1
  fi
  for package in $packages; do
    (
      set -x
      dir="${package%/*}"
      name="${package##*/}"
      platform="${dir#*/static/}"
      os="${platform%%/*}"
      arch="${platform#*/}"
      arch="${arch%%/*}"
      ext=""
      [ "$os" = windows ] && ext=".exe"
      cd "$dir"
      sha256sum -c "${name}.sha256"
      tmp=$(mktemp -d)
      case "$name" in
        *.tgz) tar -xzf "$name" -C "$tmp" ;;
        *.zip) unzip -q "$name" -d "$tmp" ;;
      esac
      test "$(ls "$tmp" | tr '\n' ' ')" = "cli-plugins doc "
      test "$(ls "$tmp/cli-plugins")" = "docker-offload${ext}"
      test -x "$tmp/cli-plugins/docker-offload${ext}"
      test -s "$tmp/doc/LICENSE"
      test -s "$tmp/doc/README.md"
      test -s "$tmp/doc/THIRD-PARTY-NOTICES"
      TARGETPLATFORM="${os}/${arch}" xx-verify --static "$tmp/cli-plugins/docker-offload${ext}"
      if [ "$os/$arch" = "$(xx-info os)/$(xx-info arch)" ]; then
        "$tmp/cli-plugins/docker-offload${ext}" docker-cli-plugin-metadata
        if [ -n "$VERSION" ]; then
          "$tmp/cli-plugins/docker-offload${ext}" docker-cli-plugin-metadata \
            | grep -F "\"Version\": \"$VERSION\""
        fi
      elif [ -n "$VERSION" ]; then
        # shortcut: substring match, so v0.7.1 also matches a v0.7.10 binary.
        # The binary cannot run here; upgrade if a way to read its version appears.
        grep -aqF "$VERSION" "$tmp/cli-plugins/docker-offload${ext}"
      fi
    )
  done
EOT

FROM verify-${DISTRO_TYPE} AS verify
