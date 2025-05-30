#!/bin/sh
set -eux
export DEBIAN_FRONTEND=noninteractive

# Define variables
ZEPHYR_GIT_ORG="${ZEPHYR_GIT_ORG:-zephyrproject-rtos}"
ZEPHYR_GIT_REPONAME="${ZEPHYR_GIT_REPONAME:-zephyr}"
ZEPHYR_GIT_REVISION="${ZEPHYR_GIT_REVISION:-main}"
ZEPHYR_SDK_VERSION="${ZEPHYR_SDK_VERSION:-0.17.1}"
ZEPHYR_ARCHITECTURE="${ARCHITECTURE:-arm}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            apt-get update -y
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install base utilities
check_packages ca-certificates curl

# Install Zephyr dependencies
if [ "$(uname -m)" = "x86_64" ]; then
    gcc_multilib="gcc-multilib";
else
    gcc_multilib="";
fi
check_packages \
    ccache \
    dfu-util \
    device-tree-compiler \
    file \
    gcc \
    g++ \
    "${gcc_multilib}" \
    git \
    gperf \
    make \
    protobuf-compiler \
    ninja-build \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    ssh

# Install python-related dependencies for Zephyr
PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install \
  -r "https://raw.githubusercontent.com/${ZEPHYR_GIT_ORG}/${ZEPHYR_GIT_REPONAME}/refs/heads/${ZEPHYR_GIT_REVISION}/scripts/requirements-base.txt"
PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install cmake protobuf~=4.25 grpcio-tools

export LC_ALL=C
export PAGER=less

# Install Node source
check_packages \
  gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

check_packages \
  clang-format \
  gdb \
  gpg \
  gpg-agent \
  less \
  libsdl2-dev \
  locales \
  nano \
  nodejs \
  python3 \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-tk \
  python3-wheel \
  socat \
  tio \
  wget \
  xz-utils

PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install \
  -r https://raw.githubusercontent.com/${ZEPHYR_GIT_ORG}/${ZEPHYR_GIT_REPONAME}/refs/heads/${ZEPHYR_GIT_REVISION}/scripts/requirements-build-test.txt \
  -r https://raw.githubusercontent.com/${ZEPHYR_GIT_ORG}/${ZEPHYR_GIT_REPONAME}/refs/heads/${ZEPHYR_GIT_REVISION}/scripts/requirements-run-test.txt
# ENV ZEPHYR_SDK_VERSION=${ZEPHYR_SDK_VERSION}

# Install Zephyr SDK
export minimal_sdk_file_name="zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-$(uname -m)_minimal" \
  && if [ "${ZEPHYR_ARCHITECTURE}" = "arm" ]; then arch_format="eabi"; else arch_format="elf"; fi \
  && if [ "${ZEPHYR_ARCHITECTURE#xtensa}" = "${ZEPHYR_ARCHITECTURE}" ]; then arch_sep="-"; else arch_sep="_"; fi

check_packages \
  wget \
  xz-utils

mkdir -p /tmp/zephyr-sdk && TMP=$(mktemp -d -p /tmp/zephyr-sdk)
(cd ${TMP} \
  && wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/${minimal_sdk_file_name}.tar.xz" \
  && tar xvfJ ${minimal_sdk_file_name}.tar.xz \
  && mv zephyr-sdk-${ZEPHYR_SDK_VERSION} /opt/ \
  && rm ${minimal_sdk_file_name}.tar.xz)

(cd /opt/zephyr-sdk-${ZEPHYR_SDK_VERSION} \
  && ./setup.sh -h -c -t ${ZEPHYR_ARCHITECTURE}${arch_sep}zephyr-${arch_format})

# Clean up
apt-get remove -y --purge \
  g++ \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  xz-utils
apt-get clean \
  && rm -rf /var/lib/apt/lists/*
