%global debug_package %{nil}

Name: docker-credential-secretservice
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: docker-credential-helpers.tgz
Summary: Credential helper backend which uses libsecret to keep Docker credentials safe
Group: Tools/Docker
License: ASL 2.0
URL: https://github.com/docker/docker-credential-helpers
Vendor: Docker
Packager: Docker <support@docker.com>

Requires: libsecret

BuildRequires: gcc
BuildRequires: libsecret-devel
BuildRequires: libtool-ltdl-devel
BuildRequires: make

%description
docker-credential-secretservice is a credential helper backend which uses libsecret to keep Docker credentials safe.

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
    CGO_ENABLED=1 make build-secretservice VERSION=%{_origversion} REVISION=%{_commit} DESTDIR=bin
popd

%check
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
ver="$(bin/docker-credential-secretservice version)"; \
    test "$ver" = "docker-credential-secretservice (github.com/docker/docker-credential-helpers) %{_origversion}" && echo "PASS: docker-credential-secretservice version OK" || (echo "FAIL: docker-credential-secretservice version ($ver) did not match" && exit 1)
popd

%install
pushd ${RPM_BUILD_DIR}/src/docker-credential-helpers
    install -D -p -m 0755 bin/docker-credential-secretservice ${RPM_BUILD_ROOT}%{_bindir}/docker-credential-secretservice
popd

%files
%{_bindir}/docker-credential-secretservice

%post

%preun

%postun

%changelog
