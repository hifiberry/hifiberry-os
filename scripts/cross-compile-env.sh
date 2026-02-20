#!/bin/bash
# Source this file in build.sh scripts to enable cross-compile support.
# If the sbuild wrapper exists in the scripts directory, prepend it to PATH
# so that sbuild invocations use the cross-compile wrapper automatically.

_CC_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$_CC_SCRIPTS_DIR/sbuild" ]; then
    echo "Cross-compile detected, using sbuild wrapper from $_CC_SCRIPTS_DIR"
    export PATH="$_CC_SCRIPTS_DIR:$PATH"
fi

unset _CC_SCRIPTS_DIR
