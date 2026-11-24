#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0
FAIL=0

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

MOCK_BIN="$TMP_ROOT/bin"
FAKE_HOME="$TMP_ROOT/home/tester"
mkdir -p "$MOCK_BIN" "$FAKE_HOME/.local/state/quickshell"

# --- Mocks ligeros para aislar red, firewall, systemctl, sudo y paru ---
cat << 'MOCK' > "$MOCK_BIN/nmcli"
#!/usr/bin/env bash
exit 0
MOCK

cat << 'MOCK' > "$MOCK_BIN/busctl"
#!/usr/bin/env bash
if [[ "$*" == *"getZones"* ]]; then
  echo 'as 3 "trust-high" "trust-med" "trust-low"'
  exit 0
fi
exit 1
MOCK

cat << 'MOCK' > "$MOCK_BIN/firewall-cmd"
#!/usr/bin/env bash
case "${1:-}" in
  --get-zones) echo "trust-high trust-med trust-low" ;;
  --get-zone-of-interface=*) echo "trust-low" ;;
  *) exit 0 ;;
esac
MOCK

cat << 'MOCK' > "$MOCK_BIN/systemctl"
#!/usr/bin/env bash
case "${1:-}" in
  is-active) echo "inactive"; exit 3 ;;
  *) exit 0 ;;
esac
MOCK

cat << 'MOCK' > "$MOCK_BIN/getent"
#!/usr/bin/env bash
if [[ "${1:-}" == "passwd" && "${2:-}" == "tester" ]]; then
  echo "tester:x:1000:1000::${FAKE_HOME}:/bin/bash"
  exit 0
fi
/usr/bin/getent "$@"
MOCK

cat << 'MOCK' > "$MOCK_BIN/paru"
#!/usr/bin/env bash
if [[ "${1:-}" == "-Qu" ]]; then
  printf 'linux 6.12.1-arch1-1 -> 6.12.2-arch1-1\nparu-bin 2.2.0-1 -> 2.2.1-1\n'
fi
MOCK

cat << 'MOCK' > "$MOCK_BIN/pacman"
#!/usr/bin/env bash
if [[ "${1:-}" == "-Qqm" ]]; then
  echo "paru-bin"
fi
MOCK

cat << 'MOCK' > "$MOCK_BIN/sudo"
#!/usr/bin/env bash
if [[ "${1:-}" == "-n" ]]; then
  shift
fi
if [[ "${1:-}" == "-u" ]]; then
  shift 2
fi
exec "$@"
MOCK

chmod +x "$MOCK_BIN"/*

assert_ok() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✓ [test] $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ [test] $name (falló inesperadamente)" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_fail() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✗ [test] $name (debía fallar y devolvió 0)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "  ✓ [test] $name"
    PASS=$((PASS + 1))
  fi
}

assert_fail_msg() {
  local name="$1" expected="$2"; shift 2
  local out rc=0
  out="$("$@" 2>&1)" || rc=$?
  if (( rc != 0 )) && [[ "$out" == *"$expected"* ]]; then
    echo "  ✓ [test] $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ [test] $name (rc=$rc, salida: ${out:-vacía})" >&2
    FAIL=$((FAIL + 1))
  fi
}

# 1. net-trust-apply status sin red no debe tronar y debe escribir JSON válido
assert_ok "net-trust-apply status sin red" \
  env PATH="$MOCK_BIN:$PATH" FAKE_HOME="$FAKE_HOME" NET_TRUST_USER=tester \
  bash "$REPO_DIR/system/net-trust/net-trust-apply" status

if jq -e '.zone == "trust-low" and .profile == "low" and .connection == ""' \
  "$FAKE_HOME/.local/state/quickshell/net-trust.json" >/dev/null 2>&1; then
  echo "  ✓ [test] net-trust.json generado con estado seguro (trust-low)"
  PASS=$((PASS + 1))
else
  echo "  ✗ [test] net-trust.json inválido o ausente" >&2
  FAIL=$((FAIL + 1))
fi

# 2. net-trust-apply rechaza perfil inválido y aborta por guard sin usuario
assert_fail "net-trust-apply rechaza perfil inválido" \
  env PATH="$MOCK_BIN:$PATH" FAKE_HOME="$FAKE_HOME" NET_TRUST_USER=tester \
  bash "$REPO_DIR/system/net-trust/net-trust-apply" set invalid-profile

assert_fail_msg "net-trust-apply aborta por guard de NET_TRUST_USER/SUDO_USER" "NET_TRUST_USER" \
  env -u SUDO_USER -u NET_TRUST_USER PATH="$MOCK_BIN:$PATH" \
  bash "$REPO_DIR/system/net-trust/net-trust-apply" status

# 3. sys-update-apply aborta por guard sin usuario (verificando mensaje real, no permisos)
assert_fail_msg "sys-update-apply aborta por guard de SYS_UPDATE_USER/SUDO_USER" "SYS_UPDATE_USER" \
  env -u SUDO_USER -u SYS_UPDATE_USER HOME="$FAKE_HOME" PATH="$MOCK_BIN:$PATH" \
  bash "$REPO_DIR/system/sys-update/sys-update-apply" upgrade

# 4. sys-update check genera JSON estructurado con REPO y AUR
assert_ok "sys-update check genera JSON con paquetes REPO/AUR" \
  env PATH="$MOCK_BIN:$PATH" HOME="$FAKE_HOME" XDG_STATE_HOME="$FAKE_HOME/.local/state" \
  bash "$REPO_DIR/scripts/sys-update" check

if jq -e '.count == 2 and .packages[0].source == "REPO" and .packages[1].source == "AUR"' \
  "$FAKE_HOME/.local/state/quickshell/sys-update.json" >/dev/null 2>&1; then
  echo "  ✓ [test] sys-update.json clasifica REPO y AUR correctamente"
  PASS=$((PASS + 1))
else
  echo "  ✗ [test] sys-update.json no tiene el formato esperado" >&2
  FAIL=$((FAIL + 1))
fi

# 5. night-light y privacy-mode status en estado limpio
assert_ok "night-light status inicializa estado limpio" \
  env HOME="$FAKE_HOME" XDG_STATE_HOME="$FAKE_HOME/.local/state" \
  bash "$REPO_DIR/scripts/night-light" status

assert_ok "privacy-mode status inicializa estado limpio" \
  env HOME="$FAKE_HOME" XDG_STATE_HOME="$FAKE_HOME/.local/state" \
  bash "$REPO_DIR/scripts/privacy-mode" status

echo "-> Smoke tests: $PASS pasaron, $FAIL fallaron."
(( FAIL == 0 ))
