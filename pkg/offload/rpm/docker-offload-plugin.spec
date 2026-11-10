%global debug_package %{nil}
# The build is reproducible, and the packaged binary is checked against the release
# checksums, so do not rewrite the ELF notes after the build.
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
BuildRequires: make

%description
Docker Offload plugin for the Docker CLI.

%prep

%build
make -C %{_srcdir} ce-release VERSION=%{_origversion} COMMIT=%{_commit} BUILD=%{_build} DATE=%{_date} BUILD_ENV_FILE=%{_buildenvfile}

%check
ver="$(%{_srcdir}/dist/docker-offload docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"
test "$ver" = "%{_origversion}" && echo "PASS: docker-offload version OK" || { echo "FAIL: docker-offload version ($ver) did not match %{_origversion}"; exit 1; }

%install
install -D -p -m 0755 %{_srcdir}/dist/docker-offload ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-offload

%files
%{_libexecdir}/docker/cli-plugins/docker-offload

%changelog
