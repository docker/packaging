%global debug_package %{nil}

Name: docker-scan-plugin
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Source0: scan-cli-plugin.tgz
Summary: Docker Scan plugin for the Docker CLI
Group: Tools/Docker
License: ASL 2.0
URL: https://github.com/docker/scan-cli-plugin
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
BuildRequires: make

%description
Docker Scan plugin for the Docker CLI.

%prep
%setup -q -c -n src -a 0

%build
pushd ${RPM_BUILD_DIR}/src/scan-cli-plugin
bash -c 'TAG_NAME="%{_origversion}" COMMIT="%{_commit}" PLATFORM_BINARY=docker-scan make native-build'
popd

%check
# FIXME: --version currently doesn't work as it makes a connection to the daemon, so using the plugin metadata instead
#${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-scan scan --accept-license --version
ver="$(${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-scan docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"; \
	test "$ver" = "%{_origversion}" && echo "PASS: docker-scan version OK" || (echo "FAIL: docker-scan version ($ver) did not match" && exit 1)

%install
pushd ${RPM_BUILD_DIR}/src/scan-cli-plugin
install -D -p -m 0755 bin/docker-scan ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-scan
popd

%files
%{_libexecdir}/docker/cli-plugins/docker-scan

%post

%preun

%postun

%changelog
