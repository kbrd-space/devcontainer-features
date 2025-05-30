#!/bin/bash

set -e

source dev-container-features-test-lib

check "cmake installed" cmake --version
check "python3 installed" python3 --version
check "dtc installed" dtc --version
check "gcc installed" gcc --version
check "node installed" node --version
check "git installed" git --version
check "west installed" west --version

reportResults
