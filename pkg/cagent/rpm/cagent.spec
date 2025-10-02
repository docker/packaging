%global debug_package %{nil}

Name: cagent
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: cagent.tgz
Summary: TODO
Group: Tools/Docker
License: Apache-2.0
URL: https://github.com/docker/cagent
Vendor: Docker
Packager: Docker <support@docker.com>

BuildRequires: bash

%description
TODO

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/cagent
    mkdir bin && \
    go build -trimpath -ldflags="-w -X github.com/docker/cagent/pkg/version.Version=%{_origversion} -X github.com/docker/cagent/pkg/version.Commit=%{_commit}" -o bin/cagent .
popd

%check
ver="$(${RPM_BUILD_ROOT}%{_bindir}/cagent version | grep 'cagent version' | awk '{print $3}')"; \
	test "$ver" = "%{_origversion}" && echo "PASS: cagent version OK" || (echo "FAIL: cagent version ($ver) did not match" && exit 1)

%install
pushd ${RPM_BUILD_DIR}/src/cagent
    install -D -p -m 0755 bin/cagent ${RPM_BUILD_ROOT}%{_bindir}/cagent
popd
for f in LICENSE README.md; do
    install -D -p -m 0644 "${RPM_BUILD_DIR}/src/cagent/$f" "cagent-docs/$f"
done

%files
%doc cagent-docs/*
%license cagent-docs/LICENSE
%{_bindir}/cagent

%post

%preun

%postun

%changelog
