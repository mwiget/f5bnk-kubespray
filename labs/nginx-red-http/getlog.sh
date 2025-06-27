#!/bin/bash
set -e

kubectl logs -f daemonset/f5-tmm -c f5-fluentbit -n default
