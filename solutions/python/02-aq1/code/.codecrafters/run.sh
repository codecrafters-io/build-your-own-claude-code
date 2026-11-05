#!/bin/sh
#
# This script is used to run your program on CodeCrafters
#
# This runs after .codecrafters/compile.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

SCRIPT_DIR="$(dirname "$0")"

# Exclude the working directory from the agent's import path.
# Apply safe-path mode only to the agent so child commands can import local files.
PYTHONPATH="$SCRIPT_DIR" exec uv run \
  --project "$SCRIPT_DIR" \
  --quiet \
  python -P -m app.main \
  "$@"