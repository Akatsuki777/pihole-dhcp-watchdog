#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with: sudo $0"
  exit 1
fi

set -e

WATCHDOG_PATH="/usr/local/bin/pihole-dhcp-watchdog.sh"
SERVICE_PATH="/etc/systemd/system/pihole-dhcp-watchdog.service"
LOG_FILE="/var/log/pihole-dhcp-watchdog.log"

echo "=== Pi-hole DHCP Watchdog Setup ==="
echo

# Prompt for variables
read -rp "Enter your Pi-hole static IP address: " PIHOLE_IP
read -rp "Enter your Wi-Fi interface name (e.g., wlan0): " WIFI_INTERFACE
read -rp "Enter your Wi-Fi SSID: " SSID

echo
echo "Setting up watchdog script at $WATCHDOG_PATH ..."
echo

# Create the watchdog script
sudo tee "$WATCHDOG_PATH" > /dev/null <<EOF
#!/bin/bash

LOG_FILE="$LOG_FILE"
PIHOLE_IP="$PIHOLE_IP" #Static IP setup for wlan interface
WIFI_INTERFACE="$WIFI_INTERFACE"
SSID="$SSID"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check WiFi connectivity
check_wifi() {
    if iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep -q "ESSID:\"$SSID\""; then
        log_message "WiFi is connected."
        return 0
    fi
    log_message "WiFi connection check failed"
    return 1
}

# Function to attempt WiFi reconnection
reconnect_wifi() {
    log_message "Attempting to reconnect WiFi..."
    
    sudo wpa_cli -i "$WIFI_INTERFACE" reassociate 
    sleep 5

}

# Function to test DHCP service using dhcping
test_dhcp_service() {
    
    if sudo dhcping -c 127.0.0.1 -s "$PIHOLE_IP" -h 00:00:00:00:00:00 >/dev/null 2>&1; then
        log_message "DHCP service test PASSED"
        return 0
    else
        log_message "DHCP service test FAILED"
        return 1
    fi
}

# Function to restart Pi-hole FTL service
restart_ftl() {
    log_message "Restarting Pi-hole FTL service..."
    sudo systemctl restart pihole-FTL
    sleep 10  
}

# Main script logic
log_message "=== Starting Pi-hole DHCP Watchdog ==="

#Check the wifi connectivity and reconnect till/if required
while ! check_wifi; do
    reconnect_wifi
    sleep 5
done

#Check the dhcp service and restart service till the dhcp responds
while ! test_dhcp_service; do
    restart_ftl
done 
EOF

# Make it executable
sudo chmod +x "$WATCHDOG_PATH"

echo
echo "Creating systemd service..."
echo

# Create systemd service
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Pi-hole DHCP Watchdog
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$WATCHDOG_PATH
Restart=always
RestartSec=300
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable pihole-dhcp-watchdog.service
sudo systemctl start pihole-dhcp-watchdog.service

echo
echo "Setup complete!"
echo "Logs are stored at:"
echo "  $LOG_FILE"
