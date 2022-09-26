%global debug_package %{nil}

Name: docker-credential-pass
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: docker-credential-helpers.tgz
Summary: Credential helper backend which uses the pass utility to keep Docker credentials safe
Group: Tools/Docker
License: ASL 2.0
URL: https://github.com/docker/docker-credential-helpers
Vendor: Docker
Packager: Docker <support@docker.com>

Requires: pass

BuildRequires: gcc
BuildRequires: libtool-ltdl-devel
BuildRequires: make

%description
docker-credential-pass is a credential helper backend which uses the pass utility to keep Docker credentials safe.

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
    CGO_ENABLED=1 make build-pass VERSION=%{_origversion} REVISION=%{_commit} DESTDIR=bin
popd

%check
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
ver="$(bin/docker-credential-pass version)"; \
    test "$ver" = "docker-credential-pass (github.com/docker/docker-credential-helpers) %{_origversion}" && echo "PASS: docker-credential-pass version OK" || (echo "FAIL: docker-credential-pass version ($ver) did not match" && exit 1)
popd

%install
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
    install -D -p -m 0755 bin/docker-credential-pass ${RPM_BUILD_ROOT}%{_bindir}/docker-credential-pass
popd

%files
%{_bindir}/docker-credential-pass

%post

%preun

%postun

%changelog
