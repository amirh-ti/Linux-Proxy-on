#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31mPlease run the install script with root privileges (or sudo):\nsudo bash install.sh\033[0m"
    exit 1
fi

echo -e "\033[0;36m[1/4] Installing prerequisites (curl, jq, python3, unzip)...\033[0m"
if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq curl jq python3 unzip
elif command -v dnf &>/dev/null; then
    dnf install -y -q curl jq python3 unzip
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm curl jq python unzip
fi

PROXY_DIR="/opt/cli-proxy"
mkdir -p "$PROXY_DIR"

echo -e "\033[0;36m[2/4] Downloading the Xray-core engine...\033[0m"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  XRAY_ARCH="64" ;;
    aarch64) XRAY_ARCH="arm64-v8a" ;;
    *) echo "Processor architecture ($ARCH) is not supported."; exit 1 ;;
esac

if [ ! -f "$PROXY_DIR/xray" ]; then
    curl -sL "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip" -o /tmp/xray.zip
    unzip -q -o /tmp/xray.zip xray geoip.dat geosite.dat -d "$PROXY_DIR/"
    chmod +x "$PROXY_DIR/xray"
    rm -f /tmp/xray.zip
fi

echo -e "\033[0;36m[3/4] Copying files and creating the Systemd service...\033[0m"
cp parser.py "$PROXY_DIR/parser.py"
chmod +x "$PROXY_DIR/parser.py"

cp proxy-functions.sh /etc/profile.d/cli-proxy.sh
chmod +x /etc/profile.d/cli-proxy.sh

# Inject into bashrc to ensure it loads in non-login shells
if ! grep -q "/etc/profile.d/cli-proxy.sh" /etc/bash.bashrc 2>/dev/null; then
    echo "[ -f /etc/profile.d/cli-proxy.sh ] && source /etc/profile.d/cli-proxy.sh" >> /etc/bash.bashrc
fi

cat > /etc/systemd/system/cli-proxy.service <<EOF
[Unit]
Description=Linux CLI Universal Proxy Core (Xray)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cli-proxy
ExecStart=/opt/cli-proxy/xray run -c /opt/cli-proxy/config.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cli-proxy.service >/dev/null 2>&1

echo -e "\033[0;32m[4/4] Installation completed successfully!\033[0m"
echo -e "To activate the commands in the current terminal, run the following command:"
echo -e "\033[0;33msource /etc/profile.d/cli-proxy.sh\033[0m"
