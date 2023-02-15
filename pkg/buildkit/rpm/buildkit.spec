%global debug_package %{nil}

Name: buildkit
Version: %{_version}
Release: %{_release}%{?dist}
Source0: buildkit.tgz
Source1: buildkit.service
Source2: buildkit.socket
Source3: buildkitd.toml
Source4: runc.tgz
Summary: Concurrent, cache-efficient, and Dockerfile-agnostic builder toolkit
License: ASL 2.0
URL: https://github.com/moby/buildkit
Vendor: Docker
Packager: Docker <support@docker.com>

# container-selinux isn't a thing in suse flavors
%if %{undefined suse_version}
# amazonlinux2 doesn't have container-selinux either
%if "%{?dist}" != ".amzn2"
Requires: container-selinux >= 2:2.74
%endif
Requires: libseccomp
%else
# SUSE flavors do not have container-selinux,
# and libseccomp is named libseccomp2
Requires: libseccomp2
%endif

BuildRequires: make
BuildRequires: gcc
BuildRequires: libtool-ltdl-devel
BuildRequires: systemd
BuildRequires: libseccomp-devel
BuildRequires: pkgconfig

%{?systemd_requires}

%description
BuildKit is concurrent, cache-efficient, and Dockerfile-agnostic builder
toolkit for converting source code to build artifacts.

%prep
rm -rf %{_topdir}/BUILD/
rm -f /go/src/github.com/moby/buildkit /go/src/github.com/opencontainers/runc
mkdir -p %{_topdir}/BUILD/src /go/src/github.com/moby /go/src/github.com/opencontainers
if [ ! -d %{_topdir}/SOURCES/buildkit ]; then
    cp -rf /usr/local/src/buildkit %{_topdir}/SOURCES/buildkit
fi
ln -s %{_topdir}/SOURCES/buildkit /go/src/github.com/moby/buildkit
if [ ! -d %{_topdir}/SOURCES/runc ]; then
    cp -rf /usr/local/src/runc %{_topdir}/SOURCES/runc
fi
ln -s %{_topdir}/SOURCES/runc /go/src/github.com/opencontainers/runc
cd %{_topdir}/BUILD/

%build
pushd /go/src/github.com/moby/buildkit
    go build \
        -mod=vendor \
        -trimpath \
        -ldflags "-X github.com/moby/buildkit/version.Version=%{_origversion} -X github.com/moby/buildkit/version.Revision=%{_commit} -X github.com/moby/buildkit/version.Package=github.com/moby/buildkit" \
        -tags "urfave_cli_no_docs apparmor seccomp" \
        -o "%{_topdir}/BUILD/bin/buildctl" \
        ./cmd/buildctl && \
    go build \
        -mod=vendor \
        -trimpath \
        -ldflags "-X github.com/moby/buildkit/version.Version=%{_origversion} -X github.com/moby/buildkit/version.Revision=%{_commit} -X github.com/moby/buildkit/version.Package=github.com/moby/buildkit" \
        -tags "urfave_cli_no_docs apparmor seccomp" \
        -o "%{_topdir}/BUILD/bin/buildkitd" \
        ./cmd/buildkitd
popd
pushd /go/src/github.com/opencontainers/runc
    CGO_ENABLED=1 GO111MODULE=auto make BINDIR="%{_topdir}/BUILD/bin" runc install
popd

%install
cd %{_topdir}/BUILD
mkdir -p %{buildroot}%{_bindir}
install -D -m 0755 bin/buildctl ${RPM_BUILD_ROOT}%{_bindir}/buildctl
install -D -m 0755 bin/buildkitd ${RPM_BUILD_ROOT}%{_bindir}/buildkitd
install -D -m 0755 bin/runc ${RPM_BUILD_ROOT}%{_bindir}/buildkit-runc
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/buildkit.service
install -D -m 0644 %{S:2} %{buildroot}%{_unitdir}/buildkit.socket
install -D -m 0644 %{S:3} %{buildroot}%{_sysconfdir}/buildkit/buildkitd.toml
mkdir -p build-docs
for file in LICENSE MAINTAINERS README.md; do
    cp "%{_topdir}/SOURCES/buildkit/$file" "build-docs/$file"
done

%post
%systemd_post buildkit.service

%preun
%systemd_preun buildkit.service

%postun
%systemd_postun_with_restart buildkit.service

%files
%doc build-docs/LICENSE build-docs/MAINTAINERS build-docs/README.md
%{_bindir}/buildctl
%{_bindir}/buildkitd
%{_bindir}/buildkit-runc
%{_unitdir}/buildkit.service
%{_unitdir}/buildkit.socket
%{_sysconfdir}/buildkit
%doc
%config(noreplace) %{_sysconfdir}/buildkit/buildkitd.toml

%changelog
