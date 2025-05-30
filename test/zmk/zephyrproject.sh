#!/bin/bash

set -e

source dev-container-features-test-lib

TMP_DIR="/tmp/zephyrproject"
mkdir -p "${TMP_DIR}"

(cd "${TMP_DIR}" && check "west init" west init)
(cd "${TMP_DIR}" && check "west update" west update --fetch-opt=--filter=tree:0)
(cd "${TMP_DIR}" && check "west zephyr export" west zephyr-export)
(cd "${TMP_DIR}/zephyr" && check "west build" west build -p always -b nrf52840_mdk samples/basic/blinky)

reportResults
