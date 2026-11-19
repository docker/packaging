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

# Verify that a built docker-ce RPM can be installed through normal DNF
# dependency resolution and that the daemon can run a container with working
# network connectivity.
#
# This test is intentionally run outside the regular verify.Dockerfile: starting
# a Docker daemon and configuring container networking requires privileges that
# are not available to BuildKit RUN steps. It installs docker-ce-cli and
# containerd.io from the public Docker RPM repository so only the locally built
# engine package is under test.

set -euo pipefail

usage() {
  echo "usage: ./verify-docker-engine-network.sh <rhel-distro> <platform>" >&2
  exit 1
}

distro=${1:-}
platform=${2:-}

if [ -z "$distro" ] || [ -z "$platform" ]; then
  usage
fi

case "$distro" in
  rhel*)
    rhel_version=${distro#rhel}
    image=${DISTRO_IMAGE:-registry.access.redhat.com/ubi${rhel_version}/ubi}
    ;;
  *)
    echo >&2 "error: unsupported distro for network verification: $distro"
    exit 1
    ;;
esac

case "$platform" in
  linux/amd64|linux/arm64)
    rpmarch=${platform#linux/}
    ;;
  *)
    echo >&2 "error: unsupported platform for network verification: $platform"
    exit 1
    ;;
esac

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
platform_dir=${platform//\//_}
rpmdir="${repo_root}/bin/pkg/docker-engine/${distro}/${platform_dir}/rhel/${rhel_version}/${rpmarch}"

if [ ! -d "$rpmdir" ]; then
  echo >&2 "error: package directory not found: $rpmdir"
  exit 1
fi

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker pull "$image"
fi

docker run --rm -i --privileged --network host \
  -e VERIFY_DISTRO="$distro" \
  -v "${rpmdir}:/rpms:ro" \
  -v "${repo_root}/hack/scripts:/scripts:ro" \
  "$image" bash -euxo pipefail -s <<'EOT'
/scripts/verify-rpm-init.sh "$VERIFY_DISTRO"

# docker-ce-cli and containerd.io are built by other package targets, so
# resolve them from the public Docker repository. The engine itself is always
# installed from the locally built RPM below.
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

rpmfile=$(find /rpms -maxdepth 1 -type f -name 'docker-ce-[0-9]*.rpm' ! -name '*.src.rpm' | sort | head -n1)
if [ -z "$rpmfile" ]; then
  echo >&2 "error: no docker-ce RPM found in /rpms"
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

# UBI does not ship iptables, so use the nftables firewall backend. The outer
# container's filesystem is typically overlay, which prevents nested overlay
# mounts, so use the vfs storage driver.
dockerd --firewall-backend=nftables --storage-driver=vfs >/var/log/dockerd.log 2>&1 &
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

client_image="registry.access.redhat.com/ubi${VERIFY_DISTRO#rhel}/ubi"
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
  curl -fsS --max-time 10 http://host.docker.internal:18080/)
if [ "$output" != "network-ok" ]; then
  echo >&2 "error: unexpected response from container network test: $output"
  exit 1
fi

echo "network verification succeeded"
EOT
