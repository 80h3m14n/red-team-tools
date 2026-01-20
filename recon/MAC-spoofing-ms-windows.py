# Microsoft Windows system MAC-changer

import winreg
import subprocess
import random


def get_interfaces():
    """Retrieve a list of available network interfaces on Windows."""
    try:
        output = subprocess.check_output(
            ["netsh", "interface", "show", "interface"], shell=True).decode("utf-8")
        interfaces = []
        for line in output.splitlines():
            if "Enabled" in line or "Disabled" in line:  # Filter lines with interface names
                parts = line.split()
                if len(parts) > 3:
                    # Interface name is the last part
                    interfaces.append(parts[-1])
        return interfaces
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while retrieving interfaces: {e}")
        return []


def generate_random_mac():
    """Generate a random valid MAC address."""
    mac = [random.randint(0x00, 0xFF) for _ in range(6)]
    # Ensure the first byte is unicast and locally administered
    mac[0] = (mac[0] & 0xFE) | 0x02
    return ":".join(f"{byte:02X}" for byte in mac)


def change_mac_address(interface_name, new_mac):
    try:
        # Open the registry key for network adapters
        reg_path = r"SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path, 0, winreg.KEY_ALL_ACCESS) as key:
            for i in range(1000):  # Iterate through subkeys
                try:
                    subkey_name = winreg.EnumKey(key, i)
                    with winreg.OpenKey(key, subkey_name) as subkey:
                        adapter_name = winreg.QueryValueEx(
                            subkey, "DriverDesc")[0]
                        if adapter_name == interface_name:
                            # Set the new MAC address
                            winreg.SetValueEx(
                                subkey, "NetworkAddress", 0, winreg.REG_SZ, new_mac)
                            print(
                                f"MAC address for {interface_name} changed to {new_mac}")
                            break
                except OSError:
                    break
        # Restart the network adapter
        subprocess.call(["netsh", "interface", "set",
                        "interface", interface_name, "disable"])
        subprocess.call(["netsh", "interface", "set",
                        "interface", interface_name, "enable"])
    except Exception as e:
        print(f"An error occurred: {e}")


# Main script
interfaces = get_interfaces()
if not interfaces:
    print("No network interfaces found. Exiting.")
    exit()

print("Available network interfaces:")
for i, iface in enumerate(interfaces, start=1):
    print(f"{i}. {iface}")

try:
    choice = int(input("Select an interface by typing the number: "))
    if choice < 1 or choice > len(interfaces):
        print("Invalid choice. Exiting.")
        exit()
    interface_name = interfaces[choice - 1]
except ValueError:
    print("Invalid input. Please enter a number. Exiting.")
    exit()

# Generate 5 random MAC addresses
print("\nGenerated MAC addresses:")
mac_addresses = [generate_random_mac() for _ in range(5)]
for i, mac in enumerate(mac_addresses, start=1):
    print(f"{i}. {mac}")

try:
    mac_choice = int(input("Select a MAC address by typing the number: "))
    if mac_choice < 1 or mac_choice > len(mac_addresses):
        print("Invalid choice. Exiting.")
        exit()
    new_mac = mac_addresses[mac_choice - 1]
except ValueError:
    print("Invalid input. Please enter a number. Exiting.")
    exit()

# Change the MAC address
change_mac_address(interface_name, new_mac)
