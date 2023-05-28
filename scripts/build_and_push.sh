#!/bin/bash

# Copyright Daniel Hawton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eux

# support other container tools, e.g. podman
CONTAINER_CLI=${CONTAINER_CLI:-docker}
# Use buildx for CI by default, allow overriding for old clients or other tools like podman
CONTAINER_BUILDER=${CONTAINER_BUILDER:-"buildx build --load"}
HUB=${HUB:-adhp}
BRANCH=${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
SHA=$(git rev-parse ${BRANCH:-main})

ADDITIONAL_BUILD_ARGS=${ADDITIONAL_BUILD_ARGS:-}
# Allow overriding of the GOLANG_IMAGE by having it set in the environment
if [[ -n "${GOLANG_IMAGE:-}" ]]; then
  ADDITIONAL_BUILD_ARGS+=" --build-arg GOLANG_IMAGE=${GOLANG_IMAGE}"
fi

pushd docker

${CONTAINER_CLI} ${CONTAINER_BUILDER} --target build_tools \
  ${ADDITIONAL_BUILD_ARGS} \
  -t "${HUB}/build-tools:${SHA}" \
  -t "${HUB}/build-tools:${BRANCH}-latest" \
  .

if [[ -z "${DRY_RUN:-}" ]]; then
  ${CONTAINER_CLI} push "${HUB}/build-tools:${SHA}"
  ${CONTAINER_CLI} push "${HUB}/build-tools:${BRANCH}-latest"
fi

popd
