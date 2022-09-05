# syntax=docker/dockerfile:1

# Copyright 2022 Docker Packaging authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG LICENSE_TYPE="apache"
ARG LICENSE_COPYRIGHT_HOLDER="Docker Packaging authors"
ARG LICENSE_FILES=".*\(Dockerfile\|\.go\|\.hcl\|\.mk\|\.sh\)"

FROM ghcr.io/google/addlicense:v1.0.0 AS addlicense

FROM alpine:3.16 AS base
WORKDIR /src
RUN apk add --no-cache cpio findutils git

FROM base AS license-set
ARG LICENSE_TYPE
ARG LICENSE_COPYRIGHT_HOLDER
ARG LICENSE_FILES
RUN --mount=type=bind,target=.,rw \
    --mount=from=addlicense,source=/app/addlicense,target=/usr/bin/addlicense \
    find . -regex "${LICENSE_FILES}" | xargs addlicense -v -c "${LICENSE_COPYRIGHT_HOLDER}" -l "${LICENSE_TYPE}" \
    && mkdir /out \
    && find . -regex "${LICENSE_FILES}" | cpio -pdm /out

FROM scratch AS license-update
COPY --from=license-set /out /

FROM base AS license-validate
ARG LICENSE_TYPE
ARG LICENSE_COPYRIGHT_HOLDER
ARG LICENSE_FILES
RUN --mount=type=bind,target=. \
    --mount=from=addlicense,source=/app/addlicense,target=/usr/bin/addlicense \
    find . -regex "${LICENSE_FILES}" | xargs addlicense -v -check -c "${LICENSE_COPYRIGHT_HOLDER}" -l "${LICENSE_TYPE}"
