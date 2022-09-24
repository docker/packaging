%global debug_package %{nil}

Name: docker-buildx-plugin
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: buildx.tgz
Summary: Docker Buildx plugin for the Docker CLI
Group: Tools/Docker
License: ASL 2.0
URL: https://github.com/docker/buildx
Vendor: Docker
Packager: Docker <support@docker.com>

# CentOS 7 and RHEL 7 do not yet support weak dependencies.
#
# Note that we're not using <= 7 here, to account for other RPM distros, such
# as Fedora, which would not have the rhel macro set (so default to 0).
%if 0%{?rhel} != 7
Enhances: docker-ce-cli
%endif

BuildRequires: bash

%description
Docker Buildx plugin extends build capabilities with BuildKit.

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/buildx
	go build \
		-mod=vendor \
		-trimpath \
		-ldflags="-X github.com/docker/buildx/version.Version=%{_origversion} -X github.com/docker/buildx/version.Revision=%{_commit} -X github.com/docker/buildx/version.Package=github.com/docker/buildx" \
		-o "bin/docker-buildx" \
		./cmd/buildx
popd

%check
ver="$(${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-buildx docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"; \
	test "$ver" = "%{_origversion}" && echo "PASS: docker-buildx version OK" || (echo "FAIL: docker-buildx version ($ver) did not match" && exit 1)

%install
pushd ${RPM_BUILD_DIR}/src/buildx
    install -D -p -m 0755 bin/docker-buildx ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-buildx
popd
for f in LICENSE MAINTAINERS README.md; do
    install -D -p -m 0644 "${RPM_BUILD_DIR}/src/buildx/$f" "docker-buildx-plugin-docs/$f"
done

%files
%doc docker-buildx-plugin-docs/*
%license docker-buildx-plugin-docs/LICENSE
%{_libexecdir}/docker/cli-plugins/docker-buildx

%post

%preun

%postun

%changelog
