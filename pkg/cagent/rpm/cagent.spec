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
cagent is a powerful multi-agent AI runtime that enables you to create,
configure, and orchestrate specialized AI agents that work together to solve
complex problems. Each agent can be equipped with specific tools, knowledge
domains, and capabilities.

Key features:
 * Multi-agent architecture with hierarchical task delegation
 * Declarative YAML-based agent configuration
 * MCP (Model Context Protocol) integration for extensible tooling
 * Support for multiple AI providers (OpenAI, Anthropic, Google Gemini, Docker Model Runner)
 * Built-in reasoning tools (think, todo, memory) for complex problem-solving
 * Docker Hub integration for sharing and distributing agent configurations
 * Event-driven streaming architecture for real-time responses

cagent makes it easy to build agent teams where specialized agents collaborate,
each bringing their own expertise and tools to handle specific aspects of user
requests. Perfect for developers building AI-powered workflows and automation.

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
