#!/usr/bin/env python3
"""
Cloudflare Tunnel Route Updater - ONE SCRIPT TO RULE THEM ALL
Gets current service IPs and updates tunnel routes via Cloudflare API
"""

import requests
import json
import subprocess
import sys

def get_service_ips():
    """Get current service IPs from Kubernetes"""
    try:
        # Get Grafana service IP
        grafana_ip = subprocess.check_output([
            "kubectl", "get", "service", "prometheus-operator-grafana", 
            "-n", "prometheus", "-o", "jsonpath={.spec.clusterIP}"
        ]).decode().strip()
        
        grafana_port = subprocess.check_output([
            "kubectl", "get", "service", "prometheus-operator-grafana", 
            "-n", "prometheus", "-o", "jsonpath={.spec.ports[0].port}"
        ]).decode().strip()
        
        # Get Alertmanager service IP  
        alertmanager_ip = subprocess.check_output([
            "kubectl", "get", "service", "prometheus-operator-kube-p-alertmanager", 
            "-n", "prometheus", "-o", "jsonpath={.spec.clusterIP}"
        ]).decode().strip()
        
        alertmanager_port = subprocess.check_output([
            "kubectl", "get", "service", "prometheus-operator-kube-p-alertmanager", 
            "-n", "prometheus", "-o", "jsonpath={.spec.ports[1].port}"
        ]).decode().strip()
        
        return {
            "grafana": f"{grafana_ip}:{grafana_port}",
            "alertmanager": f"{alertmanager_ip}:{alertmanager_port}"
        }
    except Exception as e:
        print(f"❌ Error getting service IPs: {e}")
        sys.exit(1)

def update_tunnel_routes(api_token, account_id, tunnel_name, routes):
    """Update tunnel routes via Cloudflare API"""
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    base_url = "https://api.cloudflare.com/client/v4"
    
    try:
        # Get tunnel
        url = f"{base_url}/accounts/{account_id}/cfd_tunnel"
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        tunnels = response.json()["result"]
        tunnel = None
        for t in tunnels:
            if t["name"] == tunnel_name:
                tunnel = t
                break
        
        if not tunnel:
            print(f"❌ Tunnel '{tunnel_name}' not found")
            return False
        
        tunnel_id = tunnel["id"]
        print(f"✅ Found tunnel '{tunnel_name}' with ID: {tunnel_id}")
        
        # Get current config
        url = f"{base_url}/accounts/{account_id}/cfd_tunnel/{tunnel_id}/configurations"
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        current_config = response.json()["result"]
        print(f"📋 Current config: {json.dumps(current_config, indent=2)}")
        
        # Create new ingress rules matching the current format
        ingress_rules = []
        for route in routes:
            rule = {
                "service": route["service"],
                "hostname": route["hostname"],
                "originRequest": {}
            }
            ingress_rules.append(rule)
            print(f"🔗 Added route: {route['hostname']} → {route['service']}")
        
        # Add catch-all rule
        ingress_rules.append({"service": "http_status:404"})
        
        # Create new config matching the current format
        new_config = {
            "config": {
                "ingress": ingress_rules,
                "warp-routing": {"enabled": False}
            }
        }
        
        # Update tunnel config
        url = f"{base_url}/accounts/{account_id}/cfd_tunnel/{tunnel_id}/configurations"
        response = requests.put(url, headers=headers, json=new_config)
        response.raise_for_status()
        result = response.json()["result"]
        
        print(f"✅ Tunnel configuration updated successfully!")
        print(f"📊 New config version: {result.get('config', {}).get('version', 'unknown')}")
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"❌ API Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Main function - ONE SCRIPT TO RULE THEM ALL"""
    print("🔧 Cloudflare Tunnel Route Updater")
    print("=" * 40)
    
    # Configuration
    API_TOKEN = "tP3kBAHW393AZzcZbnW5pdlIj5tWHf9kkcuO8OnN"
    ACCOUNT_ID = "a2862058e1cc276aa01de068d23f6e1f"
    TUNNEL_NAME = "homelab"
    
    # Get current service IPs
    print("📡 Getting current service IPs...")
    service_ips = get_service_ips()
    print(f"   • Grafana: {service_ips['grafana']}")
    print(f"   • Alertmanager: {service_ips['alertmanager']}")
    
    # Create routes with current IPs
    routes = [
        {
            "hostname": "lucena.cloud",
            "service": f"http://{service_ips['grafana']}",
            "path": "*"
        },
        {
            "hostname": "alertmanager.lucena.cloud", 
            "service": f"http://{service_ips['alertmanager']}",
            "path": "*"
        },
        {
            "hostname": "grafana.lucena.cloud",
            "service": f"http://{service_ips['grafana']}",
            "path": "*"
        }
    ]
    
    # Update routes
    success = update_tunnel_routes(API_TOKEN, ACCOUNT_ID, TUNNEL_NAME, routes)
    
    if success:
        print("\n🎉 Tunnel routes updated successfully!")
        print("📋 Updated routes:")
        for route in routes:
            print(f"   • {route['hostname']} → {route['service']}")
    else:
        print("\n❌ Failed to update tunnel routes")
        print("💡 You may need to update routes manually in Cloudflare dashboard")
        sys.exit(1)

if __name__ == "__main__":
    main()
