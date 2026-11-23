#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo $0" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${NET_TRUST_USER:-${SUDO_USER:-}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "✗ Error: ejecuta con sudo desde un usuario real o define NET_TRUST_USER." >&2
  exit 1
fi

echo "==> 1. Habilitando servicios base (systemd-resolved, firewalld)"
systemctl enable --now systemd-resolved firewalld
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "==> 2. Configurando zonas de firewalld (trust-high, trust-med, trust-low)"
existing_zones=" $(firewall-cmd --permanent --get-zones) "
for z in trust-high trust-med trust-low; do
  if [[ "$existing_zones" != *" $z "* ]]; then
    firewall-cmd --permanent --new-zone="$z" >/dev/null
  fi
done

# Servicios y puertos en comandos separados (requisito de firewall-cmd)
firewall-cmd --permanent --zone=trust-high \
  --add-service=ssh \
  --add-service=mdns >/dev/null

firewall-cmd --permanent --zone=trust-high \
  --add-port=22000/tcp \
  --add-port=22000/udp \
  --add-port=21027/udp \
  --add-port=53317/tcp \
  --add-port=53317/udp >/dev/null

firewall-cmd --permanent --zone=trust-low --set-target=DROP >/dev/null

# Recargar PRIMERO para que runtime reconozca las zonas nuevas, y luego fijar default
firewall-cmd --reload >/dev/null
firewall-cmd --set-default-zone=trust-low >/dev/null

echo "==> 3. Instalando controlador raíz y dispatcher de NetworkManager"
install -o root -g root -m 755 "$SCRIPT_DIR/net-trust-apply" /usr/local/bin/net-trust-apply
install -o root -g root -m 755 "$SCRIPT_DIR/90-net-trust" /etc/NetworkManager/dispatcher.d/90-net-trust

echo "==> 4. Configurando regla sudoers para $TARGET_USER"
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/net-trust-apply\n' "$TARGET_USER" \
  > /etc/sudoers.d/zz-net-trust
chmod 440 /etc/sudoers.d/zz-net-trust
visudo -cf /etc/sudoers.d/zz-net-trust

systemctl reload NetworkManager 2>/dev/null || true
echo "==> Listo."
