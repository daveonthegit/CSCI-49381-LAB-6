#!/bin/bash

echo "Starting firewall..."
IPTABLES="/sbin/iptables"

# Define experimental interface and IPs
ETH="eth1"
SERVER_IP="10.0.1.1"
CLIENT_IP="10.0.1.2"

# === Flush existing rules
echo "[1] Flushing existing rules..."
$IPTABLES -F
$IPTABLES -X
$IPTABLES -t nat -F
$IPTABLES -t nat -X

# === Allow all loopback traffic
echo "[2] Allow loopback..."
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# === Allow ESTABLISHED and RELATED traffic
echo "[3] Allow established connections..."
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# === Allow SSH from client only
echo "[4] Allow SSH from client..."
$IPTABLES -A INPUT -i $ETH -p tcp -s $CLIENT_IP --dport 22 -m state --state NEW -j ACCEPT

# === Allow outbound TCP: SSH, HTTP, SMTP
echo "[5] Allow outbound TCP..."
$IPTABLES -A OUTPUT -o $ETH -p tcp --dport 22 -m state --state NEW -j ACCEPT
$IPTABLES -A OUTPUT -o $ETH -p tcp --dport 80 -m state --state NEW -j ACCEPT
$IPTABLES -A OUTPUT -o $ETH -p tcp --dport 25 -m state --state NEW -j ACCEPT

# === Default DROP policies (must come after accepts!)
echo "[6] Set default policy to DROP..."
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

# === Anti-spoofing
echo "[7] Drop spoofed packets from self..."
$IPTABLES -A INPUT -i $ETH -s $SERVER_IP -j DROP

# === Allow inbound HTTP and MySQL from client
echo "[8] Allow HTTP and MySQL from client..."
$IPTABLES -A INPUT -i $ETH -p tcp -s $CLIENT_IP --dport 80 -m state --state NEW -j ACCEPT
$IPTABLES -A INPUT -i $ETH -p tcp -s $CLIENT_IP --dport 3306 -m state --state NEW -j ACCEPT

# === Allow inbound UDP 10000–10005 from client
echo "[9] Allow inbound UDP ports 10000–10005 from client..."
$IPTABLES -A INPUT -i $ETH -p udp -s $CLIENT_IP --dport 10000:10005 -j ACCEPT

# === Allow outbound UDP 10006–10010 to client
echo "[10] Allow outbound UDP ports 10006–10010 to client..."
$IPTABLES -A OUTPUT -o $ETH -p udp -d $CLIENT_IP --dport 10006:10010 -j ACCEPT

# === Allow ICMP
echo "[11] Allow ping (ICMP)..."
$IPTABLES -A INPUT -i $ETH -p icmp --icmp-type 8 -j ACCEPT     # echo-request (ping in)
$IPTABLES -A OUTPUT -o $ETH -p icmp --icmp-type 0 -j ACCEPT    # echo-reply (ping out)
$IPTABLES -A OUTPUT -o $ETH -p icmp --icmp-type 8 -j ACCEPT    # optional: ping from server

echo "[✓] Firewall rules applied."
