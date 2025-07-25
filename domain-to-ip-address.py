import socket

# Prompt the user to enter a URL
url = input("Enter the URL (e.g., 'facebook.com'): ").strip()

# Ensure the input is not empty
if url:
    try:
        # Get the IP addresses associated with the URL
        ip_addresses = socket.gethostbyname_ex(url)[2]

        if ip_addresses:
            print(f"IP addresses for {url}:")
            for ip in ip_addresses:
                print(ip)
        else:
            print("No IP addresses found for the given URL.")

    except socket.gaierror:
        print(
            "Invalid URL or network error. Please ensure the URL is correct and try again.")
else:
    print("URL cannot be empty. Please enter a valid URL.")


'''
import socket
ip = socket.gethostbyname("facebook.com")
print(ip)
'''
