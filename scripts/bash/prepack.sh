#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

yarn clean
yarn compile

mkdir -p contracts/build/contracts
cp -rfn artifacts/contracts/**/*.json contracts/build/contracts
cp -rfn artifacts/contracts/**/**/*.json contracts/build/contracts
rm -rf contracts/build/contracts/*.dbg.json
