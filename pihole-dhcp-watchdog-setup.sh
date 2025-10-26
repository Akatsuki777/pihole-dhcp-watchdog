#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with: sudo $0"
  exit 1
fi

set -e

WATCHDOG_PATH="/usr/local/bin/pihole-dhcp-watchdog.sh"
COOLDOWN_FILE="/tmp/pihole-dhcp-watchdog.cooldown"
SERVICE_PATH="/etc/systemd/system/pihole-dhcp-watchdog.service"
LOG_FILE="/var/log/pihole-dhcp-watchdog.log"
COOLDOWN_PERIOD=600

if [[ "$1" == "uninstall" ]]; then
  echo "=== Uninstalling Pi-hole DHCP Watchdog ==="

  # Stop and disable service if exists
  if systemctl list-unit-files | grep -q "pihole-dhcp-watchdog.service"; then
    systemctl stop pihole-dhcp-watchdog.service 2>/dev/null || true
    systemctl disable pihole-dhcp-watchdog.service 2>/dev/null || true
  fi

  # Remove files
  rm -f "$SERVICE_PATH" "$WATCHDOG_PATH" "$COOLDOWN_FILE"

  read -rp "Do you also want to delete the log file ($LOG_FILE)? [y/N]: " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -f "$LOG_FILE"
    echo "Log file removed."
  fi

  systemctl daemon-reload
  echo "Uninstallation complete."
  exit 0
fi


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
COOLDOWN_FILE="$COOLDOWN_FILE"
WIFI_INTERFACE="$WIFI_INTERFACE"
SSID="$SSID"
COOLDOWN_PERIOD="$COOLDOWN_PERIOD"

log_message() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
}

# Function to attempt WiFi reconnection
bounce_wifi() {
    log_message "Attempting to reconnect WiFi..."
    
    sudo ip link set \$WIFI_INTERFACE down
    sleep 5
    sudo ip link set \$WIFI_INTERFACE up

}

# Main script logic
log_message "=== Starting Pi-hole DHCP Watchdog ==="

#Check if in cooldown
if [ -f "\$COOLDOWN_FILE" ]; then
    COOLDOWN_TIME=\$(stat -c %Y "\$COOLDOWN_FILE")
    CURRENT_TIME=\$(date +%s)
    ELAPSED=\$((CURRENT_TIME - COOLDOWN_TIME))
    
    if [ \$ELAPSED -lt \$COOLDOWN_PERIOD ]; then
        log_message "Exiting: Still under cooldown"
        exit 0
    else
        rm -f "\$COOLDOWN_FILE"
    fi
fi

#Check if corrupt beacon in the past 5 minutes
if sudo journalctl -k --since="5 minutes ago"| grep "\$WIFI_INTERFACE.*corrupt beacon"; then
    log_message "Corrupt beacon detected..."
    log_message "Bouncing Wifi..."

    touch "\$COOLDOWN_FILE"

    bounce_wifi

    log_message "Successfully bounced Wifi!"
fi

EOF

# Make it executable
sudo chmod +x "$WATCHDOG_PATH"

echo
echo "Creating systemd service..."
echo

#Create Log file
echo
echo "Creating log file..."
echo
sudo mkdir -p "$(dirname "$LOG_FILE")"

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
