# Docker Packaging

## :test_tube: Work in progress

This repository is considered **EXPERIMENTAL** and under active development
until further notice. Please refer to [`docker-ce-packaging` repository](https://github.com/docker/docker-ce-packaging)
to request changes to the packaging process.

## About

This repository creates packages (apk, deb, rpm, static) for various projects
and are published as a Docker image on Docker Hub.

## Prerequisites

Before building packages, you need to have `docker` and [Buildx CLI plugin](https://docs.docker.com/build/buildx/install/)
installed and use a compatible [Buildx driver](https://docs.docker.com/build/building/drivers/)
to be able to build multi plaform packages:

```shell
# create docker-container builder and use it by default
# https://docs.docker.com/build/building/drivers/docker-container/
$ docker buildx create --driver docker-container --name mybuilder --use --bootstrap
```

> **Note**
>
> Some packages don't have cross-compilation support and therefore QEMU will
> be used. As it can be slow, it is recommended to use a builder with native
> nodes like we do in CI. See ["Set up remote builders" step](.github/workflows/.build.yml)
> for more details.

If you just want to build packages only for your current platform, you can set
`LOCAL_PLATFORM=1` environment variable.

## Usage

`common` folder contains helpers that will be used by the main `Makefile` and
also across projects in [pkg](pkg) folder like the list of supported apk, deb
and rpm releases to produce.

`Makefile` contains targets to build specific or all packages and will output
to `./bin` folder.

```shell
# build debian packages for buildx project
$ make deb-buildx
# build deb and rpm packages for all projects
$ make deb rpm
# build deb and rpm packages for all projects (only local platform)
$ LOCAL_PLATFORM=1 make deb rpm
```

Each [project](pkg) has also its own `Makefile`, `Dockerfile` and bake
definition to build and push packages.

```shell
$ cd pkg/buildx/
# build all packages (shortand for pkg-apk pkg-deb pkg-rpm pkg-static)
$ make pkg
# build all debian packages
$ make pkg-deb
# build debian bullseye packages
$ make build-debian11
# build centos 7 packages
$ make build-centos7
```

To create a new release of Buildx v0.9.1:

```shell
# build all packages for buildx v0.9.1 and output to ./bin folder
$ cd pkg/buildx/ 
$ BUILDX_VERSION=v0.9.1 make
# build and push image to dockereng/packaging:buildx-v0.9.1 using bake.
# "release" target will use the "bin" folder as named context to create the
# image with artifacts previously built with make.
$ docker buildx bake --push --set *.tags=dockereng/packaging:buildx-v0.9.1 release
```

Packages are published to Docker Hub as a Docker image. You can use a tool like [Undock](https://github.com/crazy-max/undock)
to extract packages:

```shell
# extract packages for all platforms and output to ./bin/undock folder
$ undock --wrap --rm-dist --all dockereng/packaging:buildx-v0.9.1 ./bin/undock
```

<details>
  <summary>tree ./bin/undock</summary>

```
./bin/undock/
├── alpine
│   ├── 3.14
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1-0_x86_64.apk
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin_0.9.1-0_armhf.apk
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin_0.9.1-0_armv7.apk
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin_0.9.1-0_aarch64.apk
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin_0.9.1-0_ppc64le.apk
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.apk
│   │   └── s390x
│   │       └── docker-buildx-plugin_0.9.1-0_s390x.apk
│   ├── 3.15
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1-0_x86_64.apk
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin_0.9.1-0_armhf.apk
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin_0.9.1-0_armv7.apk
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin_0.9.1-0_aarch64.apk
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin_0.9.1-0_ppc64le.apk
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.apk
│   │   └── s390x
│   │       └── docker-buildx-plugin_0.9.1-0_s390x.apk
│   └── 3.16
│       ├── amd64
│       │   └── docker-buildx-plugin_0.9.1-0_x86_64.apk
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin_0.9.1-0_armhf.apk
│       │   └── v7
│       │       └── docker-buildx-plugin_0.9.1-0_armv7.apk
│       ├── arm64
│       │   └── docker-buildx-plugin_0.9.1-0_aarch64.apk
│       ├── ppc64le
│       │   └── docker-buildx-plugin_0.9.1-0_ppc64le.apk
│       ├── riscv64
│       │   └── docker-buildx-plugin_0.9.1-0_riscv64.apk
│       └── s390x
│           └── docker-buildx-plugin_0.9.1-0_s390x.apk
├── centos
│   ├── 7
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   ├── 8
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   └── 9
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│       │   └── v7
│       │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│       ├── arm64
│       │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│       ├── ppc64le
│       │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│       ├── riscv64
│       │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│       └── s390x
│           └── docker-buildx-plugin-0.9.1-0.s390x.rpm
├── debian
│   ├── bullseye
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
│   │   └── s390x
│   │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
│   └── buster
│       ├── amd64
│       │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
│       │   └── v7
│       │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│       ├── arm64
│       │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
│       ├── ppc64le
│       │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
│       ├── riscv64
│       │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
│       └── s390x
│           └── docker-buildx-plugin_0.9.1-0_s390x.deb
├── fedora
│   ├── 35
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   ├── 36
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   └── 37
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│       │   └── v7
│       │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│       ├── arm64
│       │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│       ├── ppc64le
│       │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│       ├── riscv64
│       │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│       └── s390x
│           └── docker-buildx-plugin-0.9.1-0.s390x.rpm
├── oraclelinux
│   ├── 7
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   ├── 8
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-0.s390x.rpm
│   └── 9
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-0.x86_64.rpm
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin-0.9.1-0.armv6hl.rpm
│       │   └── v7
│       │       └── docker-buildx-plugin-0.9.1-0.armv7hl.rpm
│       ├── arm64
│       │   └── docker-buildx-plugin-0.9.1-0.aarch64.rpm
│       ├── ppc64le
│       │   └── docker-buildx-plugin-0.9.1-0.ppc64le.rpm
│       ├── riscv64
│       │   └── docker-buildx-plugin-0.9.1-0.riscv64.rpm
│       └── s390x
│           └── docker-buildx-plugin-0.9.1-0.s390x.rpm
├── raspbian
│   ├── bullseye
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
│   │   └── s390x
│   │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
│   └── buster
│       ├── amd64
│       │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│       ├── arm
│       │   ├── v6
│       │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
│       │   └── v7
│       │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│       ├── arm64
│       │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
│       ├── ppc64le
│       │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
│       ├── riscv64
│       │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
│       └── s390x
│           └── docker-buildx-plugin_0.9.1-0_s390x.deb
├── static
│   ├── darwin
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   └── arm64
│   │       └── docker-buildx-plugin_0.9.1.tgz
│   ├── linux
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   │   └── v7
│   │   │       └── docker-buildx-plugin_0.9.1.tgz
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   ├── ppc64le
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   ├── riscv64
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   └── s390x
│   │       └── docker-buildx-plugin_0.9.1.tgz
│   └── windows
│       ├── amd64
│       │   └── docker-buildx-plugin_0.9.1.zip
│       └── arm64
│           └── docker-buildx-plugin_0.9.1.zip
└── ubuntu
    ├── bionic
    │   ├── amd64
    │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
    │   ├── arm
    │   │   ├── v6
    │   │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
    │   │   └── v7
    │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
    │   ├── arm64
    │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
    │   ├── ppc64le
    │   │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
    │   ├── riscv64
    │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
    │   └── s390x
    │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
    ├── focal
    │   ├── amd64
    │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
    │   ├── arm
    │   │   ├── v6
    │   │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
    │   │   └── v7
    │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
    │   ├── arm64
    │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
    │   ├── ppc64le
    │   │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
    │   ├── riscv64
    │   │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
    │   └── s390x
    │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
    └── jammy
        ├── amd64
        │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
        ├── arm
        │   ├── v6
        │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
        │   └── v7
        │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
        ├── arm64
        │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
        ├── ppc64le
        │   └── docker-buildx-plugin_0.9.1-0_ppc64el.deb
        ├── riscv64
        │   └── docker-buildx-plugin_0.9.1-0_riscv64.deb
        └── s390x
            └── docker-buildx-plugin_0.9.1-0_s390x.deb

194 directories, 144 files
```
</details>

## Contributing

Want to contribute? Awesome! You can find information about contributing to
this project in the [CONTRIBUTING.md](/.github/CONTRIBUTING.md)
