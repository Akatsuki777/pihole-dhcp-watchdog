# Pi-hole DHCP Watchdog

## Description

This **systemd-based watchdog service** continuously monitors the wireless interface to check for any corrupt beacons and then bounces the interface if it happens.  
It is designed to mitigate a common issue where the DHCP server stops working after a temporary Wi-Fi disconnection when the router switches frequency on Wi-Fi–based Pi-hole setups.

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

[**Experiment 1: Failed!**]
This was a simple dhcping to the pihole device to check if a response is received, since it is on the same interface, the UDP messages will be received.

[**Experiment 2**]
This looks for corrupt beacons when reconnecting to AP after frequency change knocks the interface off the network. It bounces the interface in hopes of reconnecting.

---

## License

This project is released under the **MIT License**.  
Feel free to use, modify, and distribute it as needed.
