#!/usr/bin/env bash

PROXY_DIR="/opt/cli-proxy"
META_FILE="$PROXY_DIR/meta.json"
ACTIVE_ENV_FILE="/etc/profile.d/cli-proxy-active.sh"
APT_CONF_FILE="/etc/apt/apt.conf.d/99cli-proxy"

# 1. Enable proxy system-wide
proxy-on() {
    if [ ! -f "$PROXY_DIR/config.json" ]; then
        echo -e "\033[0;31m[!] No config has been set yet. Please run the proxy-config command first.\033[0m"
        return 1
    fi

    sudo systemctl start cli-proxy.service
    if ! systemctl is-active --quiet cli-proxy.service; then
        echo -e "\033[0;31m[✗] Error starting the proxy core service!\033[0m"
        return 1
    fi

    # Set in the current terminal
    export http_proxy="http://127.0.0.1:10809"
    export https_proxy="http://127.0.0.1:10809"
    export all_proxy="socks5h://127.0.0.1:10808"
    export HTTP_PROXY="http://127.0.0.1:10809"
    export HTTPS_PROXY="http://127.0.0.1:10809"
    export ALL_PROXY="socks5h://127.0.0.1:10808"
    export no_proxy="localhost,127.0.0.1,::1"

    # Set permanently for future terminals
    sudo bash -c "cat > $ACTIVE_ENV_FILE" <<EOF
export http_proxy="http://127.0.0.1:10809"
export https_proxy="http://127.0.0.1:10809"
export all_proxy="socks5h://127.0.0.1:10808"
export HTTP_PROXY="http://127.0.0.1:10809"
export HTTPS_PROXY="http://127.0.0.1:10809"
export ALL_PROXY="socks5h://127.0.0.1:10808"
export no_proxy="localhost,127.0.0.1,::1"
EOF

    # Set for the APT package manager (on Debian/Ubuntu distributions)
    if [ -d "/etc/apt/apt.conf.d" ]; then
        sudo bash -c "cat > $APT_CONF_FILE" <<EOF
Acquire::http::Proxy "http://127.0.0.1:10809/";
Acquire::https::Proxy "http://127.0.0.1:10809/";
EOF
    fi

    echo -e "\033[0;32m[✓] Proxy enabled system-wide (HTTP: 10809 | SOCKS5: 10808).\033[0m"
}

# 2. Disable proxy
proxy-off() {
    sudo systemctl stop cli-proxy.service

    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy
    sudo rm -f "$ACTIVE_ENV_FILE" "$APT_CONF_FILE"

    echo -e "\033[0;33m[✓] Proxy disabled and cleaned up from the system.\033[0m"
}

# 3. Set a new config
proxy-config() {
    local link="$1"
    if [ -z "$link" ]; then
        echo -e "\033[0;36mEnter your proxy link (vless, vmess, trojan, ss, socks5, socks4, http):\033[0m"
        read -r -p "> " link
    fi

    if [ -z "$link" ]; then
        echo -e "\033[0;31m[!] No link was entered.\033[0m"
        return 1
    fi

    sudo python3 "$PROXY_DIR/parser.py" "$link"
    if [ $? -eq 0 ] && systemctl is-active --quiet cli-proxy.service; then
        sudo systemctl restart cli-proxy.service
        echo -e "\033[0;32m[↻] Proxy service restarted with the new config.\033[0m"
    fi
}

# 4. Show proxy status and IP
proxy-status() {
    echo "========================================"
    if systemctl is-active --quiet cli-proxy.service; then
        echo -e "Service status : \033[0;32mActive\033[0m"
    else
        echo -e "Service status : \033[0;31mInactive\033[0m"
    fi

    if [ -f "$META_FILE" ]; then
        local proto=$(jq -r '.protocol' "$META_FILE")
        local addr=$(jq -r '.address' "$META_FILE")
        local port=$(jq -r '.port' "$META_FILE")
        echo -e "Current protocol : \033[0;36m$proto\033[0m ($addr:$port)"
    else
        echo -e "Current protocol : \033[0;33mNot set\033[0m"
    fi

    if systemctl is-active --quiet cli-proxy.service; then
        echo "Checking exit IP through the proxy..."
        local ip_info=$(curl -s -x socks5h://127.0.0.1:10808 --max-time 6 https://ipinfo.io/json)
        if [ -n "$ip_info" ]; then
            local ip=$(echo "$ip_info" | jq -r '.ip // "Unknown"')
            local country=$(echo "$ip_info" | jq -r '.country // "Unknown"')
            local org=$(echo "$ip_info" | jq -r '.org // "Unknown"')
            echo -e "Exit IP  : \033[0;32m$ip\033[0m ($country - $org)"
        else
            echo -e "Exit IP  : \033[0;31mNo response received (timeout or broken config)\033[0m"
        fi
    fi
    echo "========================================"
}

# 5. Test proxy ping and latency
proxy-ping() {
    if [ ! -f "$META_FILE" ]; then
        echo -e "\033[0;31m[!] Please set a proxy with proxy-config first.\033[0m"
        return 1
    fi

    local addr=$(jq -r '.address' "$META_FILE")
    local port=$(jq -r '.port' "$META_FILE")

    echo -e "\033[0;36m[*] Testing ping to server $addr:$port ...\033[0m"

    # Real ping test from inside the proxy tunnel to Cloudflare/Google
    if ! systemctl is-active --quiet cli-proxy.service; then
        echo -e "\033[0;33m[!] Service is off. Starting it temporarily for the test...\033[0m"
        sudo systemctl start cli-proxy.service
        local temp_started=1
        sleep 1
    fi

    local time_sec=$(curl -x socks5h://127.0.0.1:10808 -o /dev/null -s -w "%{time_total}" --connect-timeout 5 http://cp.cloudflare.com/generate_204)
    if [ $? -eq 0 ]; then
        local time_ms=$(awk "BEGIN {printf \"%.0f\", $time_sec * 1000}")
        echo -e "\033[0;32m[✓] Real proxy ping (HTTP 204): ${time_ms} ms\033[0m"
    else
        echo -e "\033[0;31m[✗] Error: proxy is not responding (Timeout)!\033[0m"
    fi

    if [ "$temp_started" = "1" ]; then
        sudo systemctl stop cli-proxy.service
    fi
}

# 6. Show supported protocol types and their formats
proxy-types() {
    cat << 'EOF'
====================================================================
 List of supported protocols and their input formats in proxy-config
====================================================================
 1. VLESS (TCP / WS / gRPC / TLS / Reality)
    Format : vless://uuid@ip:port?type=ws&security=tls&sni=domain.com#name

 2. VMess (Standard Base64 URI)
    Format : vmess://eyJ2IjoiMiIsInBzIjoi...

 3. Trojan (TLS / WS / TCP)
    Format : trojan://password@domain.com:443?security=tls&sni=domain.com#name

 4. Shadowsocks (SS)
    Format : ss://base64(method:password)@ip:port#name

 5. SOCKS5 (with or without password)
    Format : socks5://user:pass@ip:port  or  socks5://ip:port

 6. SOCKS4
    Format : socks4://ip:port

 7. HTTP / HTTPS
    Format : http://user:pass@ip:port    or  http://ip:port
====================================================================
EOF
}
