#!/bin/sh
#
# This script is used to run your program on CodeCrafters
#
# This runs after .codecrafters/compile.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

export UV_WORKING_DIR="$(dirname "$0")"
exec uv run --quiet -m app.main "$@"