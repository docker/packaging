# Docker Packaging

## About

This repository creates packages (apk, deb, rpm, static) for various projects
and are published as a Docker image on Docker Hub.

## Usage

`vars.mk` contains variables that will be used by the main `Makefile` and
also across projects in [pkg](pkg) folder. It contains the list of apk,
deb and rpm releases to produce and repos with current versions of projects.

`Makefile` contains targets to build specific or all packages and will output
to `./bin` folder:

```shell
# build debian packages for buildx project
$ make deb-buildx
# build deb and rpm packages for all projects
$ make deb rpm
```

Each [project](pkg) has also its own `Makefile`, `Dockerfile` and bake
definition to build and push packages in two steps:

```shell
# build all packages for buildx v0.9.1 and output to ./bin folder
$ cd pkg/buildx/ 
$ BUILDX_VERSION=v0.9.1 make pkg
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
./bin/undock
├── darwin
│   ├── amd64
│   │   └── docker-buildx-plugin_0.9.1.tgz
│   └── arm64
│       └── docker-buildx-plugin_0.9.1.tgz
├── linux
│   ├── amd64
│   │   ├── docker-buildx-plugin-0.9.1-centos7.x86_64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-centos8.x86_64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora33.x86_64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora34.x86_64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora35.x86_64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora36.x86_64.rpm
│   │   ├── docker-buildx-plugin_0.9.1-debian10_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-debian11_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-r0_x86_64.apk
│   │   ├── docker-buildx-plugin_0.9.1-raspbian10_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-raspbian11_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu1804_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2004_amd64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2204_amd64.deb
│   │   └── docker-buildx-plugin_0.9.1.tgz
│   ├── arm
│   │   ├── v6
│   │   │   ├── docker-buildx-plugin-0.9.1-centos7.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin-0.9.1-centos8.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin-0.9.1-fedora33.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin-0.9.1-fedora34.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin-0.9.1-fedora35.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin-0.9.1-fedora36.armv6hl.rpm
│   │   │   ├── docker-buildx-plugin_0.9.1-debian10_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-debian11_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-r0_armhf.apk
│   │   │   ├── docker-buildx-plugin_0.9.1-raspbian10_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-raspbian11_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-ubuntu1804_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-ubuntu2004_armel.deb
│   │   │   ├── docker-buildx-plugin_0.9.1-ubuntu2204_armel.deb
│   │   │   └── docker-buildx-plugin_0.9.1.tgz
│   │   └── v7
│   │       ├── docker-buildx-plugin-0.9.1-centos7.armv7hl.rpm
│   │       ├── docker-buildx-plugin-0.9.1-centos8.armv7hl.rpm
│   │       ├── docker-buildx-plugin-0.9.1-fedora33.armv7hl.rpm
│   │       ├── docker-buildx-plugin-0.9.1-fedora34.armv7hl.rpm
│   │       ├── docker-buildx-plugin-0.9.1-fedora35.armv7hl.rpm
│   │       ├── docker-buildx-plugin-0.9.1-fedora36.armv7hl.rpm
│   │       ├── docker-buildx-plugin_0.9.1-debian10_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-debian11_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-r0_armv7.apk
│   │       ├── docker-buildx-plugin_0.9.1-raspbian10_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-raspbian11_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-ubuntu1804_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-ubuntu2004_armhf.deb
│   │       ├── docker-buildx-plugin_0.9.1-ubuntu2204_armhf.deb
│   │       └── docker-buildx-plugin_0.9.1.tgz
│   ├── arm64
│   │   ├── docker-buildx-plugin-0.9.1-centos7.aarch64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-centos8.aarch64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora33.aarch64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora34.aarch64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora35.aarch64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora36.aarch64.rpm
│   │   ├── docker-buildx-plugin_0.9.1-debian10_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-debian11_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-r0_aarch64.apk
│   │   ├── docker-buildx-plugin_0.9.1-raspbian10_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-raspbian11_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu1804_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2004_arm64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2204_arm64.deb
│   │   └── docker-buildx-plugin_0.9.1.tgz
│   ├── ppc64le
│   │   ├── docker-buildx-plugin-0.9.1-centos7.ppc64le.rpm
│   │   ├── docker-buildx-plugin-0.9.1-centos8.ppc64le.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora33.ppc64le.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora34.ppc64le.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora35.ppc64le.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora36.ppc64le.rpm
│   │   ├── docker-buildx-plugin_0.9.1-debian10_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-debian11_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-r0_ppc64le.apk
│   │   ├── docker-buildx-plugin_0.9.1-raspbian10_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-raspbian11_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu1804_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2004_ppc64el.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2204_ppc64el.deb
│   │   └── docker-buildx-plugin_0.9.1.tgz
│   ├── riscv64
│   │   ├── docker-buildx-plugin-0.9.1-centos7.riscv64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-centos8.riscv64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora33.riscv64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora34.riscv64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora35.riscv64.rpm
│   │   ├── docker-buildx-plugin-0.9.1-fedora36.riscv64.rpm
│   │   ├── docker-buildx-plugin_0.9.1-debian10_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-debian11_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-r0_riscv64.apk
│   │   ├── docker-buildx-plugin_0.9.1-raspbian10_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-raspbian11_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu1804_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2004_riscv64.deb
│   │   ├── docker-buildx-plugin_0.9.1-ubuntu2204_riscv64.deb
│   │   └── docker-buildx-plugin_0.9.1.tgz
│   └── s390x
│       ├── docker-buildx-plugin-0.9.1-centos7.s390x.rpm
│       ├── docker-buildx-plugin-0.9.1-centos8.s390x.rpm
│       ├── docker-buildx-plugin-0.9.1-fedora33.s390x.rpm
│       ├── docker-buildx-plugin-0.9.1-fedora34.s390x.rpm
│       ├── docker-buildx-plugin-0.9.1-fedora35.s390x.rpm
│       ├── docker-buildx-plugin-0.9.1-fedora36.s390x.rpm
│       ├── docker-buildx-plugin_0.9.1-debian10_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-debian11_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-r0_s390x.apk
│       ├── docker-buildx-plugin_0.9.1-raspbian10_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-raspbian11_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-ubuntu1804_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-ubuntu2004_s390x.deb
│       ├── docker-buildx-plugin_0.9.1-ubuntu2204_s390x.deb
│       └── docker-buildx-plugin_0.9.1.tgz
└── windows
    ├── amd64
    │   └── docker-buildx-plugin_0.9.1.zip
    └── arm64
        └── docker-buildx-plugin_0.9.1.zip

15 directories, 109 files
```
</details>

## Contributing

Want to contribute? Awesome! You can find information about contributing to
this project in the [CONTRIBUTING.md](/.github/CONTRIBUTING.md)
