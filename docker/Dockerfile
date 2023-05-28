ARG GOLANG_VERSION=1.20.4
ARG UBUNTU_VERSION=jammy

FROM golang:${GOLANG_VERSION} AS binary_tools_context

ENV GOLANGCI_LINT_VERSION=v1.52.2
ENV HADOLINT_VERSION=v2.12.0
ENV HUGO_VERSION=0.111.3
ENV SHELLCHECK_VERSION=v0.9.0
ENV SU_EXEC_VERSION=0.2

WORKDIR /tmp
ENV GOPATH=/tmp/go
ENV OUTDIR=/out
RUN mkdir -p ${OUTDIR}/usr/bin
RUN mkdir -p ${OUTDIR}/usr/local

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common \
  unzip \
  xz-utils

# Install su-exec which is a tool that operates like sudo without the overhead
ADD https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz /tmp
RUN tar -xzvf v${SU_EXEC_VERSION}.tar.gz
WORKDIR /tmp/su-exec-${SU_EXEC_VERSION}
RUN make
RUN cp -a su-exec ${OUTDIR}/usr/bin

WORKDIR /tmp

# Install shellcheck
RUN wget -nv -O "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz"
RUN tar -xJf "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" -C /tmp
RUN mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck ${OUTDIR}/usr/bin

# Install golangci-lint
RUN go install -ldflags="-s -w" github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION} 

# Install Hadolint linter
RUN set -eux; \
  \
  case $(uname -m) in \
  x86_64) HADOLINT_BINARY=hadolint-Linux-x86_64;; \
  aarch64) HADOLINT_BINARY=hadolint-Linux-arm64;; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac; \
  \
  wget -nv -O ${OUTDIR}/usr/bin/hadolint https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/${HADOLINT_BINARY}; \
  chmod 555 ${OUTDIR}/usr/bin/hadolint

# Install Hugo
RUN set -eux; \
  \
  case $(uname -m) in \
  x86_64) HUGO_TAR=hugo_${HUGO_VERSION}_Linux-64bit.tar.gz;; \
  aarch64) HUGO_TAR=hugo_${HUGO_VERSION}_Linux-ARM64.tar.gz;; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac; \
  \
  wget -nv -O /tmp/${HUGO_TAR} https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR}; \
  tar -xzvf /tmp/${HUGO_TAR} -C /tmp; \
  mv /tmp/hugo ${OUTDIR}/usr/bin

# Move go tools
RUN mv /tmp/go/bin/* ${OUTDIR}/usr/bin

FROM ubuntu:${UBUNTU_VERSION} AS ruby_tools_context

ENV DEBIAN_FRONTEND=noninteractive
ENV AWESOMEBOT_VERSION=1.20.0
ENV HTML_PROOFER_VERSION=3.19.0
ENV MDL_VERSION=0.12.0
ENV RUBY_VERSION=3.2.2

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  gnupg2 \
  software-properties-common \
  build-essential \
  zlib1g-dev \
  cmake \
  pkg-config \
  libssl-dev \
  git \
  ruby3.0 \
  ruby3.0-dev

RUN gem install --no-wrappers --no-document awesome_bot -v ${AWESOMEBOT_VERSION}
RUN gem install --no-wrappers --no-document html-proofer -v ${HTML_PROOFER_VERSION}
RUN gem install --no-wrappers --no-document mdl -v ${MDL_VERSION}

# Install nvm and node
FROM ubuntu:${UBUNTU_VERSION} AS node_tools_context

ENV NODEJS_VERSION=18.16.0
ENV MARKDOWN_SPELLCHECK_VERSION=v1.3.1

WORKDIR /node

RUN apt-get update && apt-get install -y --no-install-recommends \
  wget ca-certificates

RUN set -eux; \
  case $(uname -m) in \
  x86_64) NODEJS_TAR=node-v${NODEJS_VERSION}-linux-x64.tar.gz;; \
  aarch64) NODEJS_TAR=node-v${NODEJS_VERSION}-linux-arm64.tar.gz;; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac; \
  wget -nv -O /tmp/${NODEJS_TAR} https://nodejs.org/download/release/v${NODEJS_VERSION}/${NODEJS_TAR}; \
  tar -xzf /tmp/${NODEJS_TAR} --strip-components=1 -C /usr/local

ADD https://nodejs.org/download/release/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-headers.tar.gz /tmp
RUN tar -xzf /tmp/node-v${NODEJS_VERSION}-headers.tar.gz --strip-components=1 -C /usr/local

RUN npm init -y && \
  npm install --omit=dev --global \
  npm@latest \
  markdown-spellcheck@"${MARKDOWN_SPELLCHECK_VERSION}"

FROM ubuntu:${UBUNTU_VERSION} AS base_os_context

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common \
  ca-certificates \
  cmake \
  cmake-data \
  gcc \
  git \
  ssh \
  iptables \
  libltdl7 \
  libc-dev \
  libcurl4-openssl-dev \
  less \
  make \
  pkg-config \
  python3 \
  python3-setuptools \
  daemon \
  wget \
  rpm \
  jq \
  gettext-base \
  locales-all \
  file \
  libclang-dev \
  iproute2 \
  ipset \
  rsync \
  clang \
  llvm \
  libbpf-dev \
  net-tools \
  sudo

RUN rm -rf /var/lib/apt/lists/*
RUN rm -fr /usr/share/python
RUN rm -fr /usr/share/bash-completion
RUN rm -fr /usr/share/bug
RUN rm -fr /usr/share/doc
RUN rm -fr /usr/share/dh-python
RUN rm -fr /usr/share/locale
RUN rm -fr /usr/share/man
RUN rm -fr /tmp/*

# Run config setup in local environments
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

## Final Image

FROM scratch AS build_tools

ENV HOME=/home
ENV LANG=C.UTF-8

# Go support
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org
ENV GOSUMDB=sum.golang.org
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV GOCACHE=/gocache
ENV GOBIN=/gobin
ENV PATH=/usr/local/go/bin:/gobin:$PATH

# Ruby support
ENV RUBYOPT="-KU -E utf-8:utf-8"

# Create the file system
COPY --from=base_os_context / /
COPY --from=binary_tools_context /out/ /
COPY --from=binary_tools_context /usr/local/go /usr/local/go

COPY --from=node_tools_context /usr/local/bin /usr/local/bin
COPY --from=node_tools_context /usr/local/lib/node_modules /usr/local/lib/node_modules
#COPY --from=node_tools_context /node/node_modules /node_modules

COPY --from=ruby_tools_context /usr/bin /usr/bin
COPY --from=ruby_tools_context /usr/lib /usr/lib
COPY --from=ruby_tools_context /etc/alternatives /etc/alternatives
COPY --from=ruby_tools_context /var/lib/gems /var/lib/gems
COPY --from=ruby_tools_context /usr/local/bin /usr/local/bin

# su-exec is used in place of complex sudo setup operations
RUN chmod u+sx /usr/bin/su-exec

COPY bashrc ${HOME}/.bashrc

RUN mkdir -p /go && \
  mkdir -p /gocache && \
  mkdir -p /gobin && \
  mkdir -p /config && \
  mkdir -p /home/.cache && \
  chmod 777 /go && \
  chmod 777 /gocache && \
  chmod 777 /gobin && \
  chmod 777 /config && \
  chmod 777 /home/.cache

WORKDIR /

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]