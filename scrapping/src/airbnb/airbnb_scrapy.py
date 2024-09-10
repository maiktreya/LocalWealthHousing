import argparse
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
import os

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Function to parse command-line arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description="Airbnb Scraper")
    parser.add_argument("--url", type=str, required=True, help="URL to scrape Airbnb listings from")
    parser.add_argument("--output", type=str, default="airbnb.csv", help="Output CSV file name (default: airbnb.csv)")
    return parser.parse_args()

# Function to wait for element
def wait_for_element(driver, by, value, timeout=10):
    return WebDriverWait(driver, timeout).until(EC.presence_of_element_located((by, value)))

# Function to extract data
def extract_data(driver):
    listings_data = []
    html_content = driver.page_source
    soup = BeautifulSoup(html_content, 'html.parser')
    all_listings = soup.find_all("div", {"data-testid": "card-container"})

    for item in all_listings:
        listing = {}

        try:
            listing["property_title"] = item.find('div', {'data-testid': 'listing-card-title'}).text.strip()
        except AttributeError:
            listing["property_title"] = None

        try:
            listing["price_with_tax"] = item.find('div', {'class': '_i5duul'}).find('div', {"class": "_10d7v0r"}).text.strip().split(" total")[0]
        except AttributeError:
            listing["price_with_tax"] = None

        try:
            property_type = item.find('span', string=lambda text: text and any(word in text.lower() for word in ['apartamento', 'casa', 'habitación']))
            listing["property_type"] = property_type.text.strip() if property_type else None
        except AttributeError:
            listing["property_type"] = None

        try:
            beds_rooms = item.find('span', string=lambda text: text and any(word in text.lower() for word in ['dormitorio', 'cama', 'baño']))
            listing["beds_rooms"] = beds_rooms.text.strip() if beds_rooms else None
        except AttributeError:
            listing["beds_rooms"] = None

        listings_data.append(listing)
    
    return listings_data

# Function to handle popups
def handle_popups(driver):
    try:
        close_button = WebDriverWait(driver, 5).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@aria-label='Close']"))
        )
        close_button.click()
        logger.info("Popup closed")
    except TimeoutException:
        logger.info("No popup found or couldn't close popup")

# Main scraper function
def scrape_airbnb(url, output_file):
    # ChromeDriver path for Ubuntu
    CHROMEDRIVER_PATH = '/usr/bin/chromedriver'
    service = Service(executable_path=CHROMEDRIVER_PATH)
    options = webdriver.ChromeOptions()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")

    driver = webdriver.Chrome(service=service, options=options)

    listings_data = []
    page_limit = 20
    current_page = 1

    try:
        driver.get(url)
        wait_for_element(driver, By.CSS_SELECTOR, "[data-testid='card-container']")

        while current_page <= page_limit:
            logger.info(f"Scraping page {current_page}")
            handle_popups(driver)
            listings_data.extend(extract_data(driver))

            try:
                next_button = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.CSS_SELECTOR, "a[aria-label='Siguiente']"))
                )
                next_button.click()
                logger.info("Clicked 'Next' button")
                wait_for_element(driver, By.CSS_SELECTOR, "[data-testid='card-container']")
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
    try:
        df = pd.DataFrame(listings_data)
        df.to_csv(output_file, index=False, encoding='utf-8')
        logger.info(f"Scraped {len(listings_data)} listings. Data saved to {output_file}")
    except Exception as e:
        logger.error(f"Error saving to CSV: {str(e)}")

# Entry point for the script
if __name__ == "__main__":
    args = parse_arguments()
    scrape_airbnb(args.url, args.output)