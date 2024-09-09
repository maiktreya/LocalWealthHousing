from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
import time

PATH = '/usr/bin/chromedriver'

service = Service(executable_path=PATH)
options = webdriver.ChromeOptions()

# Optional: Run Chrome in headless mode
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(service=service, options=options)

# Navigate to the target page
driver.get("https://www.airbnb.co.in/s/Sydney--Australia/homes?adults=1&checkin=2024-05-17&checkout=2024-05-18")
time.sleep(5)

html_content = driver.page_source
print(html_content)

driver.quit()