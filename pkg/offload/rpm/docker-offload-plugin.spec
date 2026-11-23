%global debug_package %{nil}
# The build is reproducible, and the packaged binary is checked against the release
# checksums, so do not strip the binary or rewrite its ELF notes after the build.
%global __brp_strip %{nil}
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
make -C %{_srcdir} ce-release VERSION=%{_origversion} COMMIT=%{_commit} BUILD=%{_buildnum} DATE=%{_date} BUILD_ENV_FILE=%{_buildenvfile}

%check
ver="$(%{_srcdir}/dist/docker-offload docker-cli-plugin-metadata | awk '{ gsub(/[",:]/,"")}; $1 == "Version" { print $2 }')"
test "$ver" = "%{_origversion}" && echo "PASS: docker-offload version OK" || { echo "FAIL: docker-offload version ($ver) did not match %{_origversion}"; exit 1; }

%install
install -D -p -m 0755 %{_srcdir}/dist/docker-offload ${RPM_BUILD_ROOT}%{_libexecdir}/docker/cli-plugins/docker-offload
install -D -p -m 0644 %{_srcdir}/LICENSE docker-offload-plugin-docs/LICENSE
install -D -p -m 0644 %{_noticesdir}/THIRD-PARTY-NOTICES docker-offload-plugin-docs/THIRD-PARTY-NOTICES

%files
%license docker-offload-plugin-docs/LICENSE
%license docker-offload-plugin-docs/THIRD-PARTY-NOTICES
%{_libexecdir}/docker/cli-plugins/docker-offload

%changelog
