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

# Verify that a built docker-engine package can be installed through the normal
# package manager dependency resolution and that the daemon can run a container
# with working network connectivity.
#
# This test is intentionally run outside the regular verify.Dockerfile: starting
# a Docker daemon and configuring container networking requires privileges that
# are not available to BuildKit RUN steps. It installs docker-ce-cli and
# containerd.io from the public Docker repository so only the locally built
# engine package is under test.

set -euo pipefail

usage() {
  echo "usage: ./verify-docker-engine-network.sh <distro> <platform>" >&2
  exit 1
}

distro=${1:-}
platform=${2:-}

if [ -z "$distro" ] || [ -z "$platform" ]; then
  usage
fi

case "$platform" in
  linux/amd64|linux/arm64)
    os=${platform%%/*}
    arch=${platform##*/}
    ;;
  *)
    echo >&2 "error: unsupported platform for network verification: $platform"
    exit 1
    ;;
esac

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

platform_dir=${platform//\//_}
target="pkg-docker-engine-${distro}"
bake_json=$(docker buildx bake --print "$target")

distro_type=$(jq -er --arg target "$target" '.target[$target].args.DISTRO_TYPE' <<<"$bake_json")
distro_release=$(jq -er --arg target "$target" '.target[$target].args.DISTRO_RELEASE' <<<"$bake_json")
distro_suite=$(jq -er --arg target "$target" '.target[$target].args.DISTRO_SUITE' <<<"$bake_json")
distro_image=$(jq -er --arg target "$target" '.target[$target].args.DISTRO_IMAGE' <<<"$bake_json")

case "$distro_type" in
  deb|rpm)
    pkgdir="${repo_root}/bin/pkg/docker-engine/${distro}/${platform_dir}/${distro_release}/${distro_suite}/${arch}"
    ;;
  static)
    pkgdir="${repo_root}/bin/pkg/docker-engine/${distro}/${platform_dir}/${distro_release}/${os}/${arch}"
    ;;
  *)
    echo >&2 "error: unsupported package type for network verification: $distro_type"
    exit 1
    ;;
esac

if [ ! -d "$pkgdir" ]; then
  echo >&2 "error: package directory not found: $pkgdir"
  exit 1
fi

if ! docker image inspect "$distro_image" >/dev/null 2>&1; then
  docker pull "$distro_image"
fi

docker run --rm -i --privileged \
  -e VERIFY_DISTRO="$distro" \
  -e VERIFY_TYPE="$distro_type" \
  -e VERIFY_RELEASE="$distro_release" \
  -e VERIFY_SUITE="$distro_suite" \
  -v "${pkgdir}:/packages:ro" \
  -v "${repo_root}/hack/scripts:/scripts:ro" \
  "$distro_image" bash -euxo pipefail -s <<'EOT'
case "$VERIFY_TYPE" in
  rpm)
    /scripts/verify-rpm-init.sh "$VERIFY_DISTRO"
    ;;
  deb)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl python3
    ;;
  static)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl python3 tar
    ;;
esac

case "$VERIFY_TYPE" in
  rpm)
    case "$VERIFY_DISTRO" in
      centos*) docker_repo=centos ;;
      fedora*) docker_repo=fedora ;;
      *) docker_repo=rhel ;;
    esac

    # docker-ce-cli and containerd.io are built by other package targets, so
    # resolve them from the public Docker repository. The engine itself is
    # always installed from the locally built RPM below.
    dnf config-manager --add-repo "https://download.docker.com/linux/${docker_repo}/docker-ce.repo"

    rpmfile=$(find /packages -maxdepth 1 -type f -name 'docker-ce-[0-9]*.rpm' ! -name '*.src.rpm' | sort | head -n1)
    if [ -z "$rpmfile" ]; then
      echo >&2 "error: no docker-ce RPM found in /packages"
      exit 1
    fi

    expected=$(rpm -qp --qf '%{EPOCH}:%{VERSION}-%{RELEASE}' "$rpmfile")

    # Do not use --nodeps or --nosignature here: this test must exercise the
    # package's dependency metadata and the normal DNF transaction.
    dnf install -y "$rpmfile"

    installed=$(rpm -q --qf '%{EPOCH}:%{VERSION}-%{RELEASE}' docker-ce)
    if [ "$installed" != "$expected" ]; then
      echo >&2 "error: installed docker-ce ($installed) does not match local RPM ($expected)"
      exit 1
    fi
    ;;
  deb|static)
    docker_release=$VERIFY_RELEASE
    docker_suite=$VERIFY_SUITE
    if [ "$VERIFY_TYPE" = "static" ]; then
      docker_release=debian
      docker_suite=trixie
    fi

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${docker_release}/gpg" -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${docker_release} ${docker_suite} stable" > /etc/apt/sources.list.d/docker.list
    apt-get update

    if [ "$VERIFY_TYPE" = "deb" ]; then
      debfile=$(find /packages -maxdepth 1 -type f -name 'docker-ce_*.deb' | sort | head -n1)
      if [ -z "$debfile" ]; then
        echo >&2 "error: no docker-ce DEB found in /packages"
        exit 1
      fi

      expected=$(dpkg-deb -f "$debfile" Version)

      apt-get install -y "$debfile"

      installed=$(dpkg-query -W -f='${Version}' docker-ce)
      if [ "$installed" != "$expected" ]; then
        echo >&2 "error: installed docker-ce ($installed) does not match local DEB ($expected)"
        exit 1
      fi
    else
      apt-get install -y --no-install-recommends containerd.io docker-ce-cli nftables

      tgz=$(find /packages -maxdepth 1 -type f -name 'docker-engine_*.tgz' | sort | head -n1)
      if [ -z "$tgz" ]; then
        echo >&2 "error: no docker-engine archive found in /packages"
        exit 1
      fi

      expected=$(basename "$tgz" .tgz)
      expected=${expected#docker-engine_}
      tar -xzf "$tgz" --strip-components=1 -C /usr/local/bin bin

      installed=$(dockerd --version | sed -E 's/^Docker version ([^,]+),.*$/\1/')
      if [ "$installed" != "$expected" ]; then
        echo >&2 "error: installed docker-engine ($installed) does not match local archive ($expected)"
        exit 1
      fi
    fi
    ;;
esac

# UBI does not ship iptables, so use the nftables firewall backend. The outer
# container's filesystem is typically overlay, which prevents nested overlay
# mounts, so use the vfs storage driver. Keep the inner bridge subnets clear of
# the outer container network (usually 172.17.0.0/16) so both can coexist.
dockerd \
  --firewall-backend=nftables \
  --storage-driver=vfs \
  --bip=172.30.0.1/24 \
  --default-address-pool=base=172.31.0.0/16,size=24 \
  >/var/log/dockerd.log 2>&1 &
dockerd_pid=$!
http_pid=

cleanup() {
  status=$?
  trap - EXIT
  if [ -n "$http_pid" ]; then
    kill "$http_pid" 2>/dev/null || true
    wait "$http_pid" 2>/dev/null || true
  fi
  kill "$dockerd_pid" 2>/dev/null || true
  wait "$dockerd_pid" 2>/dev/null || true
  if [ "$status" -ne 0 ]; then
    cat /var/log/dockerd.log >&2
  fi
  exit "$status"
}
trap cleanup EXIT

for _ in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$dockerd_pid" 2>/dev/null; then
    echo >&2 "error: dockerd exited during startup"
    exit 1
  fi
  sleep 1
done
docker info >/dev/null

client_image=busybox:latest
docker pull "$client_image" >/dev/null

mkdir -p /srv/network-test
printf 'network-ok\n' > /srv/network-test/index.html
python3 -m http.server 18080 --bind 0.0.0.0 --directory /srv/network-test >/var/log/http.log 2>&1 &
http_pid=$!

for _ in $(seq 1 30); do
  if curl -fsS --max-time 1 http://127.0.0.1:18080/ >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

network=verify-network
docker network create "$network" >/dev/null

output=$(docker run --rm \
  --network "$network" \
  --add-host host.docker.internal:host-gateway \
  "$client_image" \
  wget -qO- http://host.docker.internal:18080/)
if [ "$output" != "network-ok" ]; then
  echo >&2 "error: unexpected response from container network test: $output"
  exit 1
fi

echo "network verification succeeded"
EOT
