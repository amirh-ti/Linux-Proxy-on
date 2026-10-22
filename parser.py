#!/usr/bin/env python3
import sys
import json
import base64
import urllib.parse
from pathlib import Path

CONFIG_PATH = Path("/opt/cli-proxy/config.json")
META_PATH = Path("/opt/cli-proxy/meta.json")

def pad_b64(data: str) -> str:
    missing_padding = len(data) % 4
    if missing_padding:
        data += '=' * (4 - missing_padding)
    
    data = data.replace('-', '+').replace('_', '/')
    return base64.b64decode(data).decode('utf-8', errors='ignore')

def parse_link(uri: str):
    uri = uri.strip()
    parsed = urllib.parse.urlparse(uri)
    scheme = parsed.scheme.lower()
    params = dict(urllib.parse.parse_qsl(parsed.query))

    outbound = {}
    meta = {"protocol": scheme.upper(), "address": "", "port": 0}

    if scheme in ["socks4", "socks5", "socks"]:
        version = "4" if scheme == "socks4" else "5"
        meta["address"], meta["port"] = parsed.hostname, parsed.port
        server_obj = {"address": parsed.hostname, "port": int(parsed.port)}
        if parsed.username and parsed.password:
            server_obj["users"] = [{"user": urllib.parse.unquote(parsed.username), "pass": urllib.parse.unquote(parsed.password)}]
        outbound = {
            "protocol": "socks",
            "settings": {"servers": [server_obj], "version": version}
        }

    elif scheme in ["http", "https"]:
        meta["address"], meta["port"] = parsed.hostname, parsed.port
        server_obj = {"address": parsed.hostname, "port": int(parsed.port)}
        if parsed.username and parsed.password:
            server_obj["users"] = [{"user": urllib.parse.unquote(parsed.username), "pass": urllib.parse.unquote(parsed.password)}]
        outbound = {
            "protocol": "http",
            "settings": {"servers": [server_obj]}
        }

    elif scheme == "vless":
        meta["address"], meta["port"] = parsed.hostname, parsed.port
        uuid = parsed.username
        security = params.get("security", "none")
        net_type = params.get("type", "tcp")

        stream_settings = {"network": net_type, "security": security}
        if security == "tls":
            stream_settings["tlsSettings"] = {"serverName": params.get("sni", parsed.hostname), "allowInsecure": False}
        elif security == "reality":
            stream_settings["realitySettings"] = {
                "serverName": params.get("sni", ""),
                "fingerprint": params.get("fp", "chrome"),
                "publicKey": params.get("pbk", ""),
                "shortId": params.get("sid", ""),
                "spiderX": params.get("spx", "/")
            }

        if net_type == "ws":
            stream_settings["wsSettings"] = {"path": params.get("path", "/"), "headers": {"Host": params.get("host", parsed.hostname)}}
        elif net_type == "grpc":
            stream_settings["grpcSettings"] = {"serviceName": params.get("serviceName", "")}

        outbound = {
            "protocol": "vless",
            "settings": {
                "vnext": [{
                    "address": parsed.hostname,
                    "port": int(parsed.port),
                    "users": [{"id": uuid, "encryption": "none", "flow": params.get("flow", "")}]
                }]
            },
            "streamSettings": stream_settings
        }

    elif scheme == "vmess":
        b64_str = uri.replace("vmess://", "")
        vmess_data = json.loads(pad_b64(b64_str))
        meta["address"], meta["port"] = vmess_data.get("add"), int(vmess_data.get("port"))
        net_type = vmess_data.get("net", "tcp")
        tls = vmess_data.get("tls", "none")

        stream_settings = {"network": net_type, "security": tls if tls else "none"}
        if tls == "tls":
            stream_settings["tlsSettings"] = {"serverName": vmess_data.get("sni") or vmess_data.get("host") or vmess_data.get("add")}
        if net_type == "ws":
            stream_settings["wsSettings"] = {"path": vmess_data.get("path", "/"), "headers": {"Host": vmess_data.get("host", "")}}

        outbound = {
            "protocol": "vmess",
            "settings": {
                "vnext": [{
                    "address": meta["address"],
                    "port": meta["port"],
                    "users": [{"id": vmess_data.get("id"), "alterId": int(vmess_data.get("aid", 0)), "security": vmess_data.get("scy", "auto")}]
                }]
            },
            "streamSettings": stream_settings
        }

    elif scheme == "trojan":
        meta["address"], meta["port"] = parsed.hostname, parsed.port
        password = urllib.parse.unquote(parsed.username)
        security = params.get("security", "tls")
        net_type = params.get("type", "tcp")

        stream_settings = {"network": net_type, "security": security}
        if security == "tls":
            stream_settings["tlsSettings"] = {"serverName": params.get("sni", parsed.hostname)}
        if net_type == "ws":
            stream_settings["wsSettings"] = {"path": params.get("path", "/"), "headers": {"Host": params.get("host", parsed.hostname)}}

        outbound = {
            "protocol": "trojan",
            "settings": {
                "servers": [{"address": parsed.hostname, "port": int(parsed.port), "password": password}]
            },
            "streamSettings": stream_settings
        }

    elif scheme == "ss":
        # Format: ss://base64(method:password)@host:port#tag
        raw_body = uri.replace("ss://", "").split("#")[0]
        if "@" in raw_body:
            user_info, host_port = raw_body.split("@", 1)
            decoded_user = pad_b64(user_info) if ":" not in urllib.parse.unquote(user_info) else urllib.parse.unquote(user_info)
            method, password = decoded_user.split(":", 1)
            host, port = host_port.split(":", 1)
        else:
            decoded = pad_b64(raw_body)
            user_part, host_port = decoded.rsplit("@", 1)
            method, password = user_part.split(":", 1)
            host, port = host_port.split(":", 1)

        meta["address"], meta["port"] = host, int(port)
        outbound = {
            "protocol": "shadowsocks",
            "settings": {
                "servers": [{"address": host, "port": int(port), "method": method, "password": password}]
            }
        }
    else:
        raise ValueError(f"Protocol '{scheme}' is not supported.")

    full_config = {
        "log": {"loglevel": "warning"},
        "inbounds": [
            {"port": 10808, "listen": "127.0.0.1", "protocol": "socks", "settings": {"udp": True}},
            {"port": 10809, "listen": "127.0.0.1", "protocol": "http"}
        ],
        "outbounds": [outbound]
    }

    CONFIG_PATH.write_text(json.dumps(full_config, indent=2))
    META_PATH.write_text(json.dumps(meta, indent=2))
    print(f"\033[0;32m[✓] Config saved successfully! ({meta['protocol']} -> {meta['address']}:{meta['port']})\033[0m")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: parser.py <proxy_link>")
        sys.exit(1)
    try:
        parse_link(sys.argv[1])
    except Exception as e:
        print(f"\033[0;31m[✗] Error processing proxy link: {e}\033[0m")
        sys.exit(1)
