#!/bin/sh
#
# This script is used to run your program on CodeCrafters
#
# This runs after .codecrafters/compile.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

SCRIPT_DIR="$(dirname "$0")"

exec julia --project="$SCRIPT_DIR" "$SCRIPT_DIR/app/main.jl" "$@"
