#!/usr/bin/env bash

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

: "${BUILDDIR=/work/build}"
: "${CLI_SRCDIR=/work/cli-src}"
: "${OUTDIR=/out}"
: "${METADATA_FILE=/metadata.env}"

set -e

if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi

if [ "$(xx-info os)" != "darwin" ]; then
  echo >&2 "error: this builder only supports Darwin"
  exit 1
fi

# Use the combined release version (DOCKER_VERSION, or the Engine version when
# unset), rather than the standalone CLI version derived from CLI_REF.
while IFS= read -r l; do
  export "${l?}"
done < "$METADATA_FILE"

xx-go --wrap
fix-cc

# Match the Darwin cross-compilation setup in pkg/docker-cli.
if [ "$(xx-info arch)" != "amd64" ]; then
  ln -sfnT /bin/true /usr/bin/llvm-strip
fi
if [ "$(xx-info arch)" = "arm64" ]; then
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
fi

cli_builddir="${BUILDDIR}/docker"
mkdir -p "$cli_builddir"
(
  set -x
  cd "${CLI_SRCDIR}"
  CGO_ENABLED=0 GO111MODULE=off VERSION="${VERSION}" GITCOMMIT="${CLI_COMMIT}" GO_LINKMODE=static TARGET="${cli_builddir}" ./scripts/build/binary
)
xx-verify --static "${cli_builddir}/docker"

pkgoutput="$OUTDIR/static/darwin/$(xx-info arch)"
mkdir -p "$pkgoutput"
workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
mkdir -p "$workdir/docker"
(
  set -x
  cp -L "${cli_builddir}/docker" "$workdir/docker/docker"
  cp "${CLI_SRCDIR}/LICENSE" "$workdir/docker/cli.LICENSE"
  cp "${CLI_SRCDIR}/README.md" "$workdir/docker/cli.README.md"
)
pkgfile="${pkgoutput}/docker-${VERSION#v}.tgz"
tar -czf "$pkgfile" -C "$workdir" docker
write-sha256sum "$pkgfile"
