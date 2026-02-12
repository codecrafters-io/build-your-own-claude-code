#!/bin/sh
#
# This script is used to run your program on CodeCrafters
#
# This runs after .codecrafters/compile.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

exec erl \
  -pa /tmp/codecrafters-build-claude-code-gleam/dev/erlang/*/ebin \
  -noshell \
  -eval 'main:main(), halt()' \
  -extra "$@"
