%global debug_package %{nil}

Name: docker-sbx
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 0
Summary: Docker Sandbox
Group: Tools/Docker
License: Proprietary AND GPL-2.0-only AND GPL-2.0-or-later AND Apache-2.0
URL: https://docs.docker.com/sandbox/
Vendor: Docker
Packager: Docker <support@docker.com>

BuildRequires: bash
Requires: ca-certificates

%description
Docker Sandbox manager.

Provides the 'sbx' command for managing Docker sandboxes.

%build
test -f /usr/local/bin/sbx
test -f /usr/local/libexec/containerd-shim-nerdbox-v1
test -f /usr/local/libexec/mkfs.erofs
test -f /usr/local/libexec/mkfs.ext4
test -f /usr/local/libexec/%{_kernel_artifact}
test -f /usr/local/libexec/%{_initrd_artifact}
test -f /usr/local/libexec/lib/libkrun.so
test -f /usr/local/share/apparmor/docker-sbx-nerdbox-shim
cp /usr/local/share/licenses/docker-sbx/LICENSE .
cp /usr/local/share/licenses/docker-sbx/GPL-2.0 .
cp /usr/local/share/licenses/docker-sbx/Apache-2.0 .

%check
${RPM_BUILD_ROOT}%{_bindir}/sbx version

%install
install -D -p -m 0755 /usr/local/bin/sbx ${RPM_BUILD_ROOT}%{_bindir}/sbx
install -D -p -m 0755 /usr/local/libexec/containerd-shim-nerdbox-v1 ${RPM_BUILD_ROOT}%{_libexecdir}/containerd-shim-nerdbox-v1
install -D -p -m 0755 /usr/local/libexec/mkfs.erofs ${RPM_BUILD_ROOT}%{_libexecdir}/mkfs.erofs
install -D -p -m 0755 /usr/local/libexec/mkfs.ext4 ${RPM_BUILD_ROOT}%{_libexecdir}/mkfs.ext4
install -D -p -m 0644 /usr/local/libexec/%{_kernel_artifact} ${RPM_BUILD_ROOT}%{_libexecdir}/%{_kernel_artifact}
install -D -p -m 0644 /usr/local/libexec/%{_initrd_artifact} ${RPM_BUILD_ROOT}%{_libexecdir}/%{_initrd_artifact}
install -D -p -m 0755 /usr/local/libexec/lib/libkrun.so ${RPM_BUILD_ROOT}%{_libexecdir}/lib/libkrun.so
install -D -p -m 0644 /usr/local/share/apparmor/docker-sbx-nerdbox-shim ${RPM_BUILD_ROOT}%{_sysconfdir}/apparmor.d/docker-sbx-nerdbox-shim
install -D -p -m 0644 /usr/local/share/doc/docker-sbx/THIRD-PARTY-NOTICES ${RPM_BUILD_ROOT}%{_docdir}/docker-sbx/THIRD-PARTY-NOTICES

%files
%{_bindir}/sbx
%{_libexecdir}/containerd-shim-nerdbox-v1
%{_libexecdir}/mkfs.erofs
%{_libexecdir}/mkfs.ext4
%{_libexecdir}/%{_kernel_artifact}
%{_libexecdir}/%{_initrd_artifact}
%{_libexecdir}/lib/libkrun.so
%config(noreplace) %{_sysconfdir}/apparmor.d/docker-sbx-nerdbox-shim
%doc %{_docdir}/docker-sbx/THIRD-PARTY-NOTICES
%license LICENSE
%license GPL-2.0
%license Apache-2.0

%post
if command -v apparmor_parser >/dev/null 2>&1 && [ -d /sys/kernel/security/apparmor ]; then
  apparmor_parser -r -W %{_sysconfdir}/apparmor.d/docker-sbx-nerdbox-shim || true
fi

%preun
if [ "$1" -eq 0 ]; then
  # Kill all running sbx processes before uninstalling.
  killall sbx 2>/dev/null || true
  if command -v apparmor_parser >/dev/null 2>&1 && [ -d /sys/kernel/security/apparmor ]; then
    apparmor_parser -R %{_sysconfdir}/apparmor.d/docker-sbx-nerdbox-shim || true
  fi
fi

%postun

%changelog
