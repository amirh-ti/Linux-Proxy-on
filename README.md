<p align="center">
  <img src="media/logo.svg" width="320" alt="Linux-Proxy-on Logo">
</p>

<h1 align="center">⚡ Linux-Proxy-on ⚡</h1>

<p align="center">
  <b>A fast, lightweight, all-in-one Linux terminal proxy manager supporting VLESS, VMess, Trojan, Shadowsocks, SOCKS4/5, and HTTP.</b>
</p>

<p align="center">
  <a href="README.fa.md"><b>فارسی</b></a> • 
  <a href="#-project-overview">Features</a> • 
  <a href="#-quick-start">Quick Start</a> • 
  <a href="#%EF%B8%8F-cli-commands--usage">Commands</a> • 
  <a href="#-architecture-and-workflow">Architecture</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Powered%20by-Xray--core-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Xray-core">
  <img src="https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Debian%20%7C%20Arch-E95420?style=for-the-badge&logo=linux&logoColor=white" alt="OS">
  <img src="https://img.shields.io/github/license/amirh-ti/Linux-Proxy-on?style=for-the-badge&color=blue" alt="License">
</p>

---

## 📌 Project Overview

Setting up modern proxy protocols (like VLESS-Reality, VMess, or Trojan) on a headless Linux server or terminal environment usually requires complex JSON configurations and manual environment variable exports. **Linux-Proxy-on** solves this issue by combining a smart URI parser with a background systemd service:
- **Python URI Parser (`parser.py`)** automatically converts standard share links (`vless://`, `vmess://`, `ss://`, `socks5://`, etc.) into valid Xray JSON configurations.
- **Xray-core** runs silently in the background via `systemd`, exposing unified local SOCKS5 (`10808`) and HTTP (`10809`) ports.
- **Bash Functions** inject proxy settings directly into your active terminal session, global profiles, and package managers (`apt`) with a single command—no terminal restart required.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🌐 Multi-Protocol Support** | Supports `VLESS` (Reality/TLS/WS/gRPC), `VMess`, `Trojan`, `Shadowsocks`, `SOCKS4/5`, and `HTTP/HTTPS`. |
| **⚡ Instant Shell Activation** | Uses native Bash functions to apply `http_proxy` and `all_proxy` immediately in the current shell session. |
| **📦 Package Manager Ready** | Automatically configures `apt` proxy rules so `sudo apt update/install` routes through the tunnel seamlessly. |
| **🔗 One-Line URI Parsing** | Paste any standard proxy link directly into the terminal—no manual JSON editing required. |
| **📊 Live Status & IP Check** | Displays systemd service status, active protocol details, and real-time outbound IP/GeoIP info. |
| **📡 Real Tunnel Ping** | Measures true HTTP 204 round-trip latency (`ms`) through the proxy tunnel rather than simple ICMP ping. |
| **🛡️ SSH-Safe Architecture** | Routes outbound traffic cleanly without dropping active incoming SSH connections on remote VPS servers. |
| **🛠️ Systemd Integration** | Runs reliably in the background with automatic restart on failure and boot persistence. |

---

<details>
<summary>📸 Click to view Terminal Demo</summary>

<br>

```text
$ proxy-config "vless://uuid@example.com:443?security=reality&sni=yahoo.com&fp=chrome&pbk=xxx&type=tcp#Germany-VPS"
[✓] Configuration saved successfully! (VLESS -> example.com:443)

$ proxy-on
[✓] System-wide proxy enabled (HTTP: 10809 | SOCKS5: 10808).

$ proxy-ping
[*] Testing tunnel latency via example.com:443 ...
[✓] Real Proxy Latency (HTTP 204): 142 ms

$ proxy-status
========================================
Service Status   : Active (Running)
Current Protocol : VLESS (example.com:443)
Checking outbound IP via proxy...
Outbound IP      : 185.x.x.x (DE - Hetzner Online GmbH)
========================================
```

</details>

---

## 🚀 Quick Start

### Prerequisites
- **Operating System:** Ubuntu 20.04+ / Debian 11+ / Fedora / Arch Linux (`amd64` / `arm64`)
- **Privileges:** Root or `sudo` access

### Installation
Run the automatic installation script. This script installs all dependencies (`curl`, `jq`, `python3`, `unzip`), downloads the latest `Xray-core` binary for your CPU architecture, and registers the terminal commands:

```bash
bash <(curl -Ls [https://raw.githubusercontent.com/amirh-ti/Linux-Proxy-on/main/install.sh](https://raw.githubusercontent.com/amirh-ti/Linux-Proxy-on/main/install.sh)) && source /etc/profile.d/cli-proxy.sh
```

### Uninstallation
To completely remove Linux-Proxy-on (including the systemd service, Xray core, and environment configs), run the uninstaller script:

```bash
bash <(curl -Ls [https://raw.githubusercontent.com/amirh-ti/Linux-Proxy-on/main/uninstall.sh](https://raw.githubusercontent.com/amirh-ti/Linux-Proxy-on/main/uninstall.sh))
```

---

## ⌨️ CLI Commands & Usage

Once installed, you can control the proxy from anywhere in your terminal using these **6 core commands**:

| Command | Description |
| :--- | :--- |
| `proxy-on` | Starts the background proxy service and sets system-wide environment & APT proxy variables. |
| `proxy-off` | Stops the proxy service and cleans up all proxy variables from the current shell and system. |
| `proxy-config` | Parses and applies a new proxy link (can be used interactively or by passing the URI as an argument). |
| `proxy-status` | Shows service health, active protocol/server, and fetches your current outbound IP and country. |
| `proxy-ping` | Tests the real connection delay (in milliseconds) through the encrypted proxy tunnel. |
| `proxy-types` | Displays a quick reference guide of all supported proxy protocols and URI formats. |

### Usage Examples

```bash
# Set a new configuration directly
proxy-config "vless://uuid@server:443?security=tls&type=ws#MyProxy"

# Or run interactively
proxy-config

# Test connection latency before enabling system-wide
proxy-ping

# Enable proxy across the system
proxy-on

# Check active status and outbound IP
proxy-status

# Disable proxy and restore direct connection
proxy-off
```

---

## 🌐 Supported Protocols

You can view supported formats anytime in the terminal by running `proxy-types`:

```text
1. VLESS (TCP / WS / gRPC / TLS / Reality)
   vless://uuid@ip:port?type=ws&security=tls&sni=domain.com#name

2. VMess (Standard Base64 URI)
   vmess://eyJ2IjoiMiIsInBzIjoi...

3. Trojan (TLS / WS / TCP)
   trojan://password@domain.com:443?security=tls&sni=domain.com#name

4. Shadowsocks (SS)
   ss://base64(method:password)@ip:port#name

5. SOCKS5 (With or Without Auth)
   socks5://user:pass@ip:port  or  socks5://ip:port

6. SOCKS4
   socks4://ip:port

7. HTTP / HTTPS
   http://user:pass@ip:port    or  http://ip:port
```

---

## 🛠️ Service Management

While `proxy-on` and `proxy-off` handle service states automatically, you can also inspect the underlying systemd service directly:

```bash
# Check background Xray service status
sudo systemctl status cli-proxy.service

# View live Xray core logs for debugging
sudo journalctl -u cli-proxy.service -f

# Manually restart the core service
sudo systemctl restart cli-proxy.service
```

---

## 🔄 Architecture and Workflow

```text
               ┌──────────────────────────────┐
               │      User Terminal CLI       │
               │   proxy-config "<uri_link>"  │
               └──────────────┬───────────────┘
                              │
                              ▼
               ┌──────────────────────────────┐
               │          parser.py           │
               │   Decodes URI & Generates    │
               │   /opt/cli-proxy/config.json │
               └──────────────┬───────────────┘
                              │
                              ▼
               ┌──────────────────────────────┐
               │     Xray-core (Systemd)      │
               │  Establishes Remote Tunnel   │
               └──────────────┬───────────────┘
                              │
               ┌──────────────┴───────────────┐
               ▼                              ▼
┌─────────────────────────────┐┌─────────────────────────────┐
│  Local SOCKS5 (Port 10808)  ││   Local HTTP (Port 10809)   │
└──────────────┬──────────────┘└──────────────┬──────────────┘
               │                              │
               └──────────────┬───────────────┘
                              │ Runs `proxy-on`
                              ▼
               ┌──────────────────────────────┐
               │   System-Wide Integration    │
               │  • Active Shell Env Vars     │
               │  • /etc/profile.d/ Globals   │
               │  • APT Package Manager Conf  │
               └──────────────────────────────┘
```

---

## 📁 Project Structure

```text
Linux-Proxy-on/
├── install.sh                 # Automated Linux installer & systemd builder
├── uninstall.sh               # Complete cleanup and removal script
├── parser.py                  # Multi-protocol URI to Xray JSON converter
├── proxy-functions.sh         # Core Bash CLI commands (injected into profile.d)
│
├── media/                     # Documentation assets and logos
│   └── logo.svg               # Project banner logo
│
├── README.md                  # English documentation
└── README.fa.md               # Persian documentation
```

---

## 🗺️ Roadmap

- [x] **Multi-protocol URI parser:** Support for VLESS, VMess, Trojan, SS, SOCKS4/5, and HTTP.
- [x] **System-wide environment & APT integration:** Instant toggle with `proxy-on` and `proxy-off`.
- [ ] **Subscription link support:** Fetch and switch between multiple configs from a base64 subscription URL.
- [ ] **Proxychains & TUN mode integration:** Force non-proxy-aware applications through the tunnel.
- [ ] **Auto-failover:** Automatically switch to the lowest-ping server when the active config drops.

---

## 🤝 Contribution and Support

Contributions to project development, submitting bug reports, and suggestions are always welcome!

1. **Fork** the project.  
2. Create a new branch (`git checkout -b feature/AmazingFeature`).  
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).  
4. **Push** the branch (`git push origin feature/AmazingFeature`).  
5. Submit a **Pull Request**.  

If **Linux-Proxy-on** was useful to you, please support it by giving a **⭐ Star** on GitHub!

---

## 📜 Acknowledgements

This project was built using the following open-source tools:
- [Xray-core](https://github.com/XTLS/Xray-core) by Project X
- [jq](https://jqlang.github.io/jq/) Command-line JSON processor
- [Python 3](https://www.python.org/) Standard Library
