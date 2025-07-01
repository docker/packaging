# Docker Packaging

## :test_tube: Experimental

This repository is considered **EXPERIMENTAL** and under active development
until further notice. Please refer to [`docker-ce-packaging` repository](https://github.com/docker/docker-ce-packaging)
to request changes to the packaging process.

## About

This repository creates packages (deb, rpm, static) for various projects and
are published as a Docker image [on Docker Hub](https://hub.docker.com/r/dockereng/packaging).

___

* [Release](#release)
* [Build](#build)
  * [Requirements](#requirements)
  * [Usage](#usage)
* [Contributing](#contributing)

## Release

Packages are published to [Docker Hub](https://hub.docker.com/r/dockereng/packaging)
as non-runnable images that only contains the artifacts. You can check the [GitHub Releases](https://github.com/docker/packaging/releases)
for the list of published Docker tags.

> [!NOTE]
> We are also publishing nightly builds using the [`nightly-<project>-<version>` tags](https://hub.docker.com/r/dockereng/packaging/tags?page=1&name=nightly-).

For testing purpose you can use a tool like [Undock](https://github.com/crazy-max/undock)
to extract packages:

```shell
# extract packages for all platforms and output to ./bin/undock folder
$ undock --wrap --rm-dist --all dockereng/packaging:buildx-v0.9.1 ./bin/undock
```

## Build

### Requirements

* [Docker](https://docs.docker.com/engine/install/) 20.10 or newer
* [Buildx](https://docs.docker.com/build/install-buildx/) 0.21.0 or newer

Before building packages, you need to use a compatible [Buildx driver](https://docs.docker.com/build/building/drivers/)
to be able to build multi-plaform packages such as `docker-container`:

```shell
# create docker-container builder and use it by default
# https://docs.docker.com/build/building/drivers/docker-container/
$ docker buildx create --driver docker-container --name mybuilder --use --bootstrap
```

> [!NOTE]
> Some packages don't have cross-compilation support, and therefore QEMU will
> be used. As it can be slow to build, it is recommended to use a builder with
> native nodes.

### Usage

```shell
# build all packages for all distros
$ docker buildx bake pkg
# build buildx package for debian 12
$ docker buildx bake pkg-buildx-debian12
# build buildx package for debian 12
$ docker buildx bake pkg-buildx-debian12
# build all packages for all distros (only local platform)
$ LOCAL_PLATFORM=1 docker buildx bake pkg
```

To create a new release for a package:

```shell
# build all distros for buildx v0.24.0 and output to ./bin folder
$ PKG_REF=v0.24.0 docker buildx bake pkg-buildx-*
# build and push image to dockereng/packaging:buildx-v0.24.0. "release" target
# will use the "bin" folder as named context to create the image with artifacts
# previously built.
$ docker buildx bake --push --set *.tags=dockereng/packaging:buildx-v0.24.0 release-buildx 
```

## Contributing

Want to contribute? Awesome! You can find information about contributing to
this project in the [CONTRIBUTING.md](/.github/CONTRIBUTING.md)
