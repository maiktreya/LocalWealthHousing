from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import pandas as pd

l = []
o = {}

# ChromeDriver path for Ubuntu
PATH = '/usr/bin/chromedriver'

service = Service(executable_path=PATH)
options = webdriver.ChromeOptions()

# Optional: Run Chrome in headless mode
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(service=service, options=options)

# URL of the first page
driver.get("https://www.airbnb.es/s/Segovia--Spain/homes?refinement_paths%5B%5D=%2Fhomes&place_id=ChIJr5ElYupOQQ0RsMvzWgeHBQM&checkin=2024-09-13&checkout=2024-09-15&adults=1")
time.sleep(2)

def extract_data():
    """Function to extract data from the current page"""
    html_content = driver.page_source
    soup = BeautifulSoup(html_content, 'html.parser')
    allData = soup.find_all("div", {"itemprop": "itemListElement"})

    for i in range(len(allData)):
        try:
            o["property-title"] = allData[i].find('div', {'data-testid': 'listing-card-title'}).text.strip()
        except:
            o["property-title"] = None

        try:
            o["price_with_tax"] = allData[i].find('div', {'class': '_i5duul'}).find('div', {"class": "_10d7v0r"}).text.strip().split(" total")[0]
        except:
            o["price_with_tax"] = None

        l.append(o.copy())

# Pagination loop with a page limit
page_limit = 3  # Set your page limit here
current_page = 1  # Start from page 1

while current_page <= page_limit:
    extract_data()  # Extract data from the current page

    try:
        # Wait until the "Next" button is available and clickable, then click it
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[@aria-label='Next']"))
        )
        next_button.click()
        time.sleep(2)  # Give some time for the next page to load
        current_page += 1  # Increment the page counter
    except Exception as e:
        print(f"Stopping due to exception or no more pages available on page {current_page}: {e}")
        break

driver.quit()

# Save data to CSV
df = pd.DataFrame(l)
df.to_csv('airbnb.csv', index=False, encoding='utf-8')
print(l)
