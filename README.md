# Pi-hole DHCP Watchdog

## Description

This **systemd-based watchdog service** continuously monitors the Pi-hole DHCP server and automatically restarts the **FTL service** if it becomes unresponsive.  
It is designed to mitigate a common issue where the DHCP server stops working after a temporary Wi-Fi disconnection when the router switches channels on Wi-Fi–based Pi-hole setups.

---

## Prerequisites

Ensure that the following dependency is installed on your system before proceeding:

- **dhcping**

You can install it using:
```bash
sudo apt install dhcping
```

---

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Akatsuki777/pihole-dhcp-watchdog.git
   ```

2. **Navigate into the directory**
   ```bash
   cd pihole-dhcp-watchdog
   ```

3. **Make the setup script executable**
   ```bash
   chmod +x pihole-dhcp-watchdog-setup.sh
   ```

4. **Run the setup**
   ```bash
   sudo ./pihole-dhcp-watchdog-setup.sh
   ```

This will automatically install and configure the watchdog service under `systemd`.

---

## Notes

This project is **experimental** and currently running on my personal setup. 

I will update this section if it is a stable solution

If you have a better solution than this bandaid of a solution, please do let me know.

---

## License

This project is released under the **MIT License**.  
Feel free to use, modify, and distribute it as needed.
