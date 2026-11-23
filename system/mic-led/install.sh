#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -o root -g root -m 644 "$SCRIPT_DIR/90-micmute-led.rules" /etc/udev/rules.d/90-micmute-led.rules
udevadm control --reload-rules
udevadm trigger --subsystem-match=leds
