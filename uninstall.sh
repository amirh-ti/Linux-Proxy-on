#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31mPlease run the uninstall script with root privileges (or sudo):\nsudo bash uninstall.sh\033[0m"
    exit 1
fi

echo -e "\033[0;36m[1/4] Stopping and disabling the cli-proxy service...\033[0m"
if systemctl is-active --quiet cli-proxy.service 2>/dev/null; then
    systemctl stop cli-proxy.service
fi
if systemctl is-enabled --quiet cli-proxy.service 2>/dev/null; then
    systemctl disable cli-proxy.service >/dev/null 2>&1
fi

echo -e "\033[0;36m[2/4] Removing the Systemd service file...\033[0m"
rm -f /etc/systemd/system/cli-proxy.service
systemctl daemon-reload

echo -e "\033[0;36m[3/4] Cleaning up network settings, APT, and terminal commands...\033[0m"
rm -f /etc/profile.d/cli-proxy.sh
rm -f /etc/profile.d/cli-proxy-active.sh
rm -f /etc/apt/apt.conf.d/99cli-proxy

if [ -f /etc/bash.bashrc ]; then
    sed -i '/\/etc\/profile\.d\/cli-proxy\.sh/d' /etc/bash.bashrc
fi

echo -e "\033[0;36m[4/4] Removing Xray-core files and the application directory...\033[0m"
rm -rf /opt/cli-proxy

echo -e "\033[0;32m[✓] ProxyCLI has been completely removed from your system!\033[0m"
echo -e "To clear the environment variables from the current terminal, run the following command or close the terminal:"
echo -e "\033[0;33munset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy\033[0m"
