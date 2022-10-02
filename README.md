# Docker Packaging

## :test_tube: Work in progress

This repository is considered **EXPERIMENTAL** and under active development
until further notice. Please refer to [`docker-ce-packaging` repository](https://github.com/docker/docker-ce-packaging)
to request changes to the packaging process.

## About

This repository creates packages (apk, deb, rpm, static) for various projects
and are published as a Docker image [on Docker Hub](https://hub.docker.com/r/dockereng/packaging).

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
> nodes like we do in CI. See ["Set up remote builders" step](.github/workflows/release.yml)
> for more details.

If you just want to build packages for your current platform, you can set
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
# build all packages
$ make
# build all debian packages
$ make pkg-deb
# build debian bullseye packages
$ make run-pkg-debian11
# build centos 7 packages
$ make run-pkg-centos7
```

To create a new release of Buildx v0.9.1:

```shell
# build all packages for buildx v0.9.1 and output to ./bin folder
$ cd pkg/buildx/ 
$ BUILDX_REF=v0.9.1 make
# build and push image to dockereng/packaging:buildx-v0.9.1 using bake.
# "release" target will use the "bin" folder as named context to create the
# image with artifacts previously built with make.
$ docker buildx bake --push --set *.tags=dockereng/packaging:buildx-v0.9.1 release
```

Packages are published to Docker Hub as a Docker image. You can use a tool like [Undock](https://github.com/crazy-max/undock)
to extract packages:

```shell
# extract packages for all platforms and output to ./bin/undock folder
$ undock --wrap --rm-dist --all dockereng/packaging:buildx-v0.9.1 ./buildx/v0.9.1
```

<details>
  <summary>tree ./bin/undock</summary>

```
./buildx/v0.9.1/
├── centos
│   ├── 7
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.el7.x86_64.rpm
│   │   └── arm64
│   │       └── docker-buildx-plugin-0.9.1-1.el7.aarch64.rpm
│   ├── 8
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.el8.x86_64.rpm
│   │   └── arm64
│   │       └── docker-buildx-plugin-0.9.1-1.el8.aarch64.rpm
│   └── 9
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-1.el9.x86_64.rpm
│       └── arm64
│           └── docker-buildx-plugin-0.9.1-1.el9.aarch64.rpm
├── debian
│   ├── bullseye
│   │   ├── amd64
│   │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.buildinfo
│   │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.changes
│   │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│   │   ├── arm
│   │   │   ├── v6
│   │   │   │   ├── docker-buildx-plugin_0.9.1-0_armel.buildinfo
│   │   │   │   ├── docker-buildx-plugin_0.9.1-0_armel.changes
│   │   │   │   └── docker-buildx-plugin_0.9.1-0_armel.deb
│   │   │   └── v7
│   │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
│   │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.changes
│   │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│   │   ├── arm64
│   │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.buildinfo
│   │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.changes
│   │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
│   │   └── s390x
│   │       ├── docker-buildx-plugin_0.9.1-0_s390x.buildinfo
│   │       ├── docker-buildx-plugin_0.9.1-0_s390x.changes
│   │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
│   └── buster
│       ├── amd64
│       │   ├── docker-buildx-plugin_0.9.1-0_amd64.buildinfo
│       │   ├── docker-buildx-plugin_0.9.1-0_amd64.changes
│       │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
│       ├── arm
│       │   └── v7
│       │       ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
│       │       ├── docker-buildx-plugin_0.9.1-0_armhf.changes
│       │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
│       └── arm64
│           ├── docker-buildx-plugin_0.9.1-0_arm64.buildinfo
│           ├── docker-buildx-plugin_0.9.1-0_arm64.changes
│           └── docker-buildx-plugin_0.9.1-0_arm64.deb
├── fedora
│   ├── 35
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.fc35.x86_64.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-1.fc35.aarch64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-1.fc35.s390x.rpm
│   ├── 36
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.fc36.x86_64.rpm
│   │   ├── arm64
│   │   │   └── docker-buildx-plugin-0.9.1-1.fc36.aarch64.rpm
│   │   └── s390x
│   │       └── docker-buildx-plugin-0.9.1-1.fc36.s390x.rpm
│   └── 37
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-1.fc37.x86_64.rpm
│       ├── arm64
│       │   └── docker-buildx-plugin-0.9.1-1.fc37.aarch64.rpm
│       └── s390x
│           └── docker-buildx-plugin-0.9.1-1.fc37.s390x.rpm
├── oraclelinux
│   ├── 7
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.el7.x86_64.rpm
│   │   └── arm64
│   │       └── docker-buildx-plugin-0.9.1-1.el7.aarch64.rpm
│   ├── 8
│   │   ├── amd64
│   │   │   └── docker-buildx-plugin-0.9.1-1.el8.x86_64.rpm
│   │   └── arm64
│   │       └── docker-buildx-plugin-0.9.1-1.el8.aarch64.rpm
│   └── 9
│       ├── amd64
│       │   └── docker-buildx-plugin-0.9.1-1.el9.x86_64.rpm
│       └── arm64
│           └── docker-buildx-plugin-0.9.1-1.el9.aarch64.rpm
├── raspbian
│   ├── bullseye
│   │   └── arm
│   │       └── v7
│   │           ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
│   │           ├── docker-buildx-plugin_0.9.1-0_armhf.changes
│   │           └── docker-buildx-plugin_0.9.1-0_armhf.deb
│   └── buster
│       └── arm
│           └── v7
│               ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
│               ├── docker-buildx-plugin_0.9.1-0_armhf.changes
│               └── docker-buildx-plugin_0.9.1-0_armhf.deb
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
    │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.buildinfo
    │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.changes
    │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
    │   ├── arm
    │   │   └── v7
    │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
    │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.changes
    │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
    │   ├── arm64
    │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.buildinfo
    │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.changes
    │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
    │   └── s390x
    │       ├── docker-buildx-plugin_0.9.1-0_s390x.buildinfo
    │       ├── docker-buildx-plugin_0.9.1-0_s390x.changes
    │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
    ├── focal
    │   ├── amd64
    │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.buildinfo
    │   │   ├── docker-buildx-plugin_0.9.1-0_amd64.changes
    │   │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
    │   ├── arm
    │   │   └── v7
    │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
    │   │       ├── docker-buildx-plugin_0.9.1-0_armhf.changes
    │   │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
    │   ├── arm64
    │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.buildinfo
    │   │   ├── docker-buildx-plugin_0.9.1-0_arm64.changes
    │   │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
    │   └── s390x
    │       ├── docker-buildx-plugin_0.9.1-0_s390x.buildinfo
    │       ├── docker-buildx-plugin_0.9.1-0_s390x.changes
    │       └── docker-buildx-plugin_0.9.1-0_s390x.deb
    └── jammy
        ├── amd64
        │   ├── docker-buildx-plugin_0.9.1-0_amd64.buildinfo
        │   ├── docker-buildx-plugin_0.9.1-0_amd64.changes
        │   └── docker-buildx-plugin_0.9.1-0_amd64.deb
        ├── arm
        │   └── v7
        │       ├── docker-buildx-plugin_0.9.1-0_armhf.buildinfo
        │       ├── docker-buildx-plugin_0.9.1-0_armhf.changes
        │       └── docker-buildx-plugin_0.9.1-0_armhf.deb
        ├── arm64
        │   ├── docker-buildx-plugin_0.9.1-0_arm64.buildinfo
        │   ├── docker-buildx-plugin_0.9.1-0_arm64.changes
        │   └── docker-buildx-plugin_0.9.1-0_arm64.deb
        └── s390x
            ├── docker-buildx-plugin_0.9.1-0_s390x.buildinfo
            ├── docker-buildx-plugin_0.9.1-0_s390x.changes
            └── docker-buildx-plugin_0.9.1-0_s390x.deb

87 directories, 97 files
```
</details>

## Contributing

Want to contribute? Awesome! You can find information about contributing to
this project in the [CONTRIBUTING.md](/.github/CONTRIBUTING.md)
