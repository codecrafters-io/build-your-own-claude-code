#!/bin/sh
#
# This script is used to compile your program on CodeCrafters
#
# This runs before .codecrafters/run.sh
#
# Learn more: https://codecrafters.io/program-interface

set -e # Exit on failure

mix escript.build
mv codecrafters_claude_code /tmp/codecrafters-build-claude-code-elixir
