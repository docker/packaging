%global debug_package %{nil}
# Keep the ELF notes so the prebuilt binary still matches its attested digest.
%global __brp_strip_comment_note %{nil}

Name: docker-offload-plugin
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Summary: Docker Offload plugin for the Docker CLI
Group: Tools/Docker
License: Proprietary
URL: https://docs.docker.com/offload/
Vendor: Docker
Packager: Docker <support@docker.com>

Enhances: docker-ce-cli

BuildRequires: bash

%description
Docker Offload plugin for the Docker CLI.

%prep

%build
test -f /usr/local/libexec/docker/cli-plugins/docker-offload

%check
ver="$(/usr/local/libexec/docker/cli-plugins/docker-offload docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"
test "$ver" = "%{_origversion}" && echo "PASS" || { echo "FAIL: got '$ver', want '%{_origversion}'"; exit 1; }

%install
install -D -p -m 0755 /usr/local/libexec/docker/cli-plugins/docker-offload ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-offload

%files
%{_libexecdir}/docker/cli-plugins/docker-offload

%changelog
