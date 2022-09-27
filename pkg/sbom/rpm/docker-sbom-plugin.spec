%global debug_package %{nil}

Name: docker-sbom-plugin
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: sbom.tgz
Summary: Plugin for Docker CLI to support SBOM creation using Syft.
Group: Tools/Docker
License: ASL 2.0
URL: https://github.com/docker/sbom
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
Plugin for Docker CLI to support SBOM creation using Syft.

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/sbom
    go build \
        -trimpath \
        -ldflags "-X github.com/docker/sbom-cli-plugin/internal/version.version=%{_origversion} -X github.com/docker/sbom-cli-plugin/internal/version.gitCommit=%{_commit}" \
        -o "./bin/docker-sbom"
popd

%check
ver="$(${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-sbom docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"; \
    test "$ver" = "%{_origversion}" && echo "PASS: docker-sbom version OK" || (echo "FAIL: docker-sbom version ($ver) did not match" && exit 1)

%install
pushd ${RPM_BUILD_DIR}/src/sbom
    install -D -p -m 0755 bin/docker-sbom ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-sbom
popd
for f in LICENSE README.md; do
    install -D -p -m 0644 "${RPM_BUILD_DIR}/src/sbom/$f" "docker-sbom-plugin-docs/$f"
done

%files
%doc docker-sbom-plugin-docs/*
%license docker-sbom-plugin-docs/LICENSE
%{_libexecdir}/docker/cli-plugins/docker-sbom

%post

%preun

%postun

%changelog
