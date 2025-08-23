import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse
from concurrent.futures import ThreadPoolExecutor
import os

# Fallback if you don't have the custom color/banner imports
def clear(): os.system("cls" if os.name == "nt" else "clear")
banner = """
______________  __________    ________     _____           _____              
__  ____/__   |/  /_  ___/    ___  __ \______  /_____________  /______________
_  /    __  /|_/ /_____ \     __  / / /  _ \  __/  _ \  ___/  __/  __ \_  ___/
/ /___  _  /  / / ____/ /     _  /_/ //  __/ /_ /  __/ /__ / /_ / /_/ /  /    
\____/  /_/  /_/  /____/      /_____/ \___/\__/ \___/\___/ \__/ \____//_/     
                    CMS Detection Tool by 80h3m14n
"""

# Colors (you can replace/remove if not needed)
class colors:
    wh = '\033[0m'
    r = '\033[91m'
    g = '\033[92m'

CMS_SIGNATURES = {
    'WordPress': {'meta': ['wp-content', 'wp-includes'], 'paths': ['/wp-login.php', '/wp-admin/'], 'classes': ['wp-']},
    'Joomla': {'meta': ['joomla'], 'paths': ['/index.php', '/administrator/'], 'classes': ['joomla']},
    'Drupal': {'meta': ['drupal'], 'paths': ['/node', '/user'], 'classes': ['drupal']},
    'Magento': {'meta': ['Magento'], 'paths': ['/checkout/onepage/', '/admin/'], 'classes': ['mage-']},
    'Shopify': {'meta': ['shopify'], 'paths': ['/cart', '/collections/'], 'classes': ['shopify-']},
    'Blogger': {'meta': ['blogger', 'blogspot'], 'paths': ['/search', '/blogger/'], 'classes': ['blogspot']},
    'PrestaShop': {'meta': ['prestashop'], 'paths': ['/admin-dev/', '/prestashop/'], 'classes': ['prestashop']},
    'Wix': {'meta': ['wix', 'wixsite'], 'paths': ['/wix/'], 'classes': ['wix-']},
    'Squarespace': {'meta': ['squarespace'], 'paths': ['/squarespace/'], 'classes': ['sqs-']},
    'Ghost': {'meta': ['ghost'], 'paths': ['/ghost/'], 'classes': ['gh-']},
    'Typo3': {'meta': ['typo3'], 'paths': ['/typo3/', '/index.php'], 'classes': ['typo3']},
    'Concrete5': {'meta': ['concrete5'], 'paths': ['/index.php', '/concrete/'], 'classes': ['concrete5']},
    'Contentful': {'meta': ['contentful'], 'paths': ['/contentful/'], 'classes': ['cf-']},
    'ExpressionEngine': {'meta': ['expressionengine'], 'paths': ['/admin.php', '/index.php'], 'classes': ['ee-']},
    'Craft CMS': {'meta': ['craftcms'], 'paths': ['/craft/'], 'classes': ['craft-']},
    'Weebly': {'meta': ['weebly'], 'paths': ['/weebly/'], 'classes': ['weebly-']},
    'Webflow': {'meta': ['webflow'], 'paths': ['/webflow/'], 'classes': ['webflow-']},
}

session = requests.Session()
add_scheme = lambda url: url if urlparse(url).scheme else 'https://' + url

def get_html(url):
    try:
        response = session.get(url, timeout=5, allow_redirects=True)
        response.raise_for_status()
        return response.text
    except requests.RequestException:
        return None

def detect_cms(url):
    html = get_html(url)
    if not html:
        return "Unknown"

    soup = BeautifulSoup(html, 'html.parser')
    for cms, sig in CMS_SIGNATURES.items():
        if any(tag in html for tag in sig['meta']) or any(path in html for path in sig['paths']) or any(soup.find(class_=cls) for cls in sig['classes']):
            return cms
    return "Unknown"

def save_result(url, cms):
    os.makedirs("Results", exist_ok=True)
    filename = "unknown.txt" if cms == "Unknown" else f"{cms}.txt"

    with open(f"Results/{filename}", "a") as f:
        f.write(url + "\n")

def process_url(url):
    cms = detect_cms(url)
    print(f"{colors.g}[+] {url} --> {cms}{colors.wh}")
    save_result(url, cms)

def scan_file(file_path, thread_count=10):
    try:
        with open(file_path, 'r') as file:
            urls = [add_scheme(url.strip()) for url in file.readlines() if url.strip()]
    except FileNotFoundError:
        print(f"{colors.r}File {file_path} not found.{colors.wh}")
        return
    
    with ThreadPoolExecutor(max_workers=thread_count) as executor:
        executor.map(process_url, urls)

def main():
    clear()
    print(banner)
    file_path = input(f"{colors.g}[+] Enter path to website list: {colors.wh}")

    while True:
        thread_input = input(f"{colors.g}[+] Number of threads: {colors.wh}")
        try:
            thread_count = int(thread_input)
            if thread_count <= 0:
                print(f"{colors.r}Error: Thread count must be greater than 0.{colors.wh}")
                continue
            break
        except ValueError:
            print(f"{colors.r}Error: Enter a valid number for thread count.{colors.wh}")

    scan_file(file_path, thread_count)

if __name__ == "__main__":
    main()
