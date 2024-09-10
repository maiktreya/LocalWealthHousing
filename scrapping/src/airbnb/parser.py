from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import time
import pandas as pd
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

l = []
o = {}  # Reset the dictionary for each item

# ChromeDriver path for Ubuntu
PATH = '/usr/bin/chromedriver'
service = Service(executable_path=PATH)
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
driver = webdriver.Chrome(service=service, options=options)

# URL of the first page
url = "https://www.airbnb.es/s/Segovia--Espa%C3%B1a--Segovia--Espa%C3%B1a/homes?refinement_paths%5B%5D=%2Fhomes&property_type_id%5B%5D=1&place_id=ChIJpTALIQA_QQ0RwPB3-yycavA&checkin=2024-09-20&checkout=2024-09-22&adults=1&tab_id=home_tab&query=Segovia%2C%20Espa%C3%B1a%2C%20Segovia%2C%20Espa%C3%B1a&flexible_trip_lengths%5B%5D=one_week&monthly_start_date=2024-10-01&monthly_length=3&monthly_end_date=2025-01-01&search_mode=regular_search&price_filter_input_type=0&price_filter_num_nights=2&channel=EXPLORE&search_type=filter_change&date_picker_type=calendar&source=structured_search_input_header"

def wait_for_element(driver, by, value, timeout=10):
    return WebDriverWait(driver, timeout).until(EC.presence_of_element_located((by, value)))

def extract_data():
    """Function to extract data from the current page"""
    html_content = driver.page_source
    soup = BeautifulSoup(html_content, 'html.parser')
    allData = soup.find_all("div", {"data-testid": "card-container"})

    for item in allData:
        o = {}  # Reset the dictionary for each item
        try:
            o["property-title"] = item.find('div', {'data-testid': 'listing-card-title'}).text.strip()
        except:
            o["property-title"] = None

        try:
            o["price_with_tax"] = item.find('div', {'class': '_i5duul'}).find('div', {"class": "_10d7v0r"}).text.strip().split(" total")[0]
        except:
            o["price_with_tax"] = None

        try:
            # Look for the property type within the listing details
            property_type = item.find('span', string=lambda text: text and any(word in text.lower() for word in ['apartamento', 'casa', 'habitación']))
            o["property-type"] = property_type.text.strip() if property_type else None
        except:
            o["property-type"] = None

        try:
            # Look for beds/rooms info
            beds_rooms = item.find('span', string=lambda text: text and any(word in text.lower() for word in ['dormitorio', 'cama', 'baño']))
            o["beds_rooms"] = beds_rooms.text.strip() if beds_rooms else None
        except:
            o["beds_rooms"] = None

        l.append(o)

def handle_popups():
    try:
        close_button = WebDriverWait(driver, 5).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@aria-label='Close']"))
        )
        close_button.click()
        logger.info("Popup closed")
    except TimeoutException:
        logger.info("No popup found or couldn't close popup")

# Pagination loop with a page limit
page_limit = 20  # Set your page limit here
current_page = 1  # Start from page 1

try:
    driver.get(url)
    time.sleep(5)  # Increased initial wait time

    # Wait for a key element to ensure the page is loaded
    wait_for_element(driver, By.CSS_SELECTOR, "[data-testid='card-container']")

    while current_page <= page_limit:
        logger.info(f"Scraping page {current_page}")
        handle_popups()
        extract_data()  # Extract data from the current page

        try:
            # Try to find the "Next" button using its aria-label
            next_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, "a[aria-label='Siguiente']"))
            )
            next_button.click()
            logger.info("Clicked 'Next' button")

            # Wait for new listings to load
            time.sleep(8)  # Adjust wait time for slower loading

            current_page += 1
        except TimeoutException:
            logger.info("No 'Next' button found or not clickable. Ending scraping.")
            break
        except Exception as e:
            logger.error(f"Error while navigating to next page: {str(e)}")
            break

except Exception as e:
    logger.error(f"An error occurred: {str(e)}")

finally:
    driver.quit()

# Save data to CSV
df = pd.DataFrame(l)
df.to_csv('airbnb.csv', index=False, encoding='utf-8')
logger.info(f"Scraped {len(l)} listings")
print(l)
