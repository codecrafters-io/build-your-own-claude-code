#!/bin/sh
#
# This script is used to compile your program on CodeCrafters
#
# This runs before .codecrafters/run.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

gleam build

rm -rf /tmp/codecrafters-build-claude-code-gleam
cp -r build /tmp/codecrafters-build-claude-code-gleam
