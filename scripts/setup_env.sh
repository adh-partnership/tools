#!/bin/bash
# shellcheck disable=SC2034

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

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"

LOCAL_ARCH=$(uname -m)

# Pass environment set target architecture to build system
if [[ ${TARGET_ARCH} ]]; then
    # Target explicitly set
    :
elif [[ ${LOCAL_ARCH} == x86_64 ]]; then
    TARGET_ARCH=amd64
else
    echo "This system's architecture, ${LOCAL_ARCH}, isn't supported"
    exit 1
fi

LOCAL_OS=$(uname)

# Pass environment set target operating-system to build system
if [[ ${TARGET_OS} ]]; then
    # Target explicitly set
    :
elif [[ $LOCAL_OS == Linux ]]; then
    TARGET_OS=linux
    readlink_flags="-f"
else
    echo "This system's OS, $LOCAL_OS, isn't supported"
    exit 1
fi

# Build image to use
TOOLS_REGISTRY_PROVIDER=${TOOLS_REGISTRY_PROVIDER:-}
PROJECT_ID=${PROJECT_ID:-adhp}
if [[ "${IMAGE_VERSION:-}" == "" ]]; then
  IMAGE_VERSION=main-latest
fi
if [[ "${IMAGE_NAME:-}" == "" ]]; then
  IMAGE_NAME=build-tools
fi

DOCKER_GID="${DOCKER_GID:-$(grep '^docker:' /etc/group | cut -f3 -d:)}"

TIMEZONE=$(readlink "$readlink_flags" /etc/localtime | sed -e 's/^.*zoneinfo\///')

TARGET_OUT="${TARGET_OUT:-$(pwd)/out/${TARGET_OS}_${TARGET_ARCH}}"
TARGET_OUT_LINUX="${TARGET_OUT_LINUX:-$(pwd)/out/linux_${TARGET_ARCH}}"

CONTAINER_TARGET_OUT="${CONTAINER_TARGET_OUT:-/work/out/${TARGET_OS}_${TARGET_ARCH}}"
CONTAINER_TARGET_OUT_LINUX="${CONTAINER_TARGET_OUT_LINUX:-/work/out/linux_${TARGET_ARCH}}"

IMG="${IMG:-${TOOLS_REGISTRY_PROVIDER}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_VERSION}}"

CONTAINER_CLI="${CONTAINER_CLI:-docker}"

ENV_BLOCKLIST="${ENV_BLOCKLIST:-^_\|^PATH=\|^GOPATH=\|^GOROOT=\|^SHELL=\|^EDITOR=\|^TMUX=\|^USER=\|^HOME=\|^PWD=\|^TERM=\|^RUBY_\|^GEM_\|^rvm_\|^SSH=\|^TMPDIR=\|^CC=\|^CXX=\|^MAKEFILE_LIST=}"

# Remove functions from the list of exported variables, they mess up with the `env` command.
for f in $(declare -F -x | cut -d ' ' -f 3);
do
  unset -f "${f}"
done

# Set conditional host mounts
CONDITIONAL_HOST_MOUNTS="${CONDITIONAL_HOST_MOUNTS:-} "

# gitconfig conditional host mount (needed for git commands inside container)
if [[ -f "${HOME}/.gitconfig" ]]; then
  CONDITIONAL_HOST_MOUNTS+="--mount type=bind,source=${HOME}/.gitconfig,destination=/home/.gitconfig,readonly "
fi

# .netrc conditional host mount (needed for git commands inside container)
if [[ -f "${HOME}/.netrc" ]]; then
  CONDITIONAL_HOST_MOUNTS+="--mount type=bind,source=${HOME}/.netrc,destination=/home/.netrc,readonly "
fi

# LOCAL_OUT should point to architecture where we are currently running versus the desired.
# This is used when we need to run a build artifact during tests or later as part of another
# target.
if [[ "${FOR_BUILD_CONTAINER:-0}" -eq "1" ]]; then
  # Override variables with container specific
  TARGET_OUT=${CONTAINER_TARGET_OUT}
  TARGET_OUT_LINUX=${CONTAINER_TARGET_OUT_LINUX}
  REPO_ROOT=/work
  LOCAL_OUT="${TARGET_OUT_LINUX}"
else
  LOCAL_OUT="${TARGET_OUT}"
fi

go_os_arch=${LOCAL_OUT##*/}
# Golang OS/Arch format
LOCAL_GO_OS=${go_os_arch%_*}
LOCAL_GO_ARCH=${go_os_arch##*_}

BUILD_WITH_CONTAINER=0

VARS=(
      CONTAINER_TARGET_OUT
      CONTAINER_TARGET_OUT_LINUX
      TARGET_OUT
      TARGET_OUT_LINUX
      LOCAL_GO_OS
      LOCAL_GO_ARCH
      LOCAL_OUT
      LOCAL_OS
      TARGET_OS
      LOCAL_ARCH
      TARGET_ARCH
      TIMEZONE
      KUBECONFIG
      CONDITIONAL_HOST_MOUNTS
      ENV_BLOCKLIST
      CONTAINER_CLI
      DOCKER_GID
      IMG
      IMAGE_NAME
      IMAGE_VERSION
      REPO_ROOT
      BUILD_WITH_CONTAINER
)

# For non container build, we need to write env to file
if [[ "${1}" == "envfile" ]]; then
  # ! does a variable-variable https://stackoverflow.com/a/10757531/374797
  for var in "${VARS[@]}"; do
    echo "${var}"="${!var}"
  done
else
  for var in "${VARS[@]}"; do
    # shellcheck disable=SC2163
    export "${var}"
  done
fi
