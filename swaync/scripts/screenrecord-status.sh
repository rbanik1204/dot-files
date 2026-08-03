#!/bin/bash
# Requires wf-recorder
if pgrep -x wf-recorder > /dev/null; then
    echo "true"
else
    echo "false"
fi
