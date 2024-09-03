# 0.1 beta AirBnB scraper by @tlaloc 03092024
import asyncio
import schedule
import time
import os
import csv
from datetime import datetime
from playwright.async_api import async_playwright  # Playwright for web scraping
from apify_client import ApifyClient  # ApifyClient for interacting with Apify API

CSV_FILE = "scraped_data.csv"

# Function to extract data from the page
async def extract_data(page):
    print("[INFO] Extracting data from the page...")
    listings = await page.evaluate(
        '''() => {
        return Array.from(document.querySelectorAll(".listing")).map(listing => ({
            title: listing.querySelector(".title").innerText,
            price: listing.querySelector(".price").innerText,
            link: listing.querySelector("a").href,
        }));
    }'''
    )
    print(f"[INFO] Extracted {len(listings)} listings.")
    return listings

# Function to handle the browsing and scraping logic
async def run_scraping(playwright):
    print("[INFO] Launching browser and navigating to the target URL...")
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context()
    page = await context.new_page()

    # Navigate to the target URL
    await page.goto("https://www.airbnb.com/s/small-town/homes")

    # Extract data from the page
    data = await extract_data(page)
    await browser.close()
    print("[INFO] Browser closed.")
    return data

# Function to handle data saving to CSV
def save_to_csv(data):
    print("[INFO] Saving data to CSV file...")
    # Check if the file exists
    file_exists = os.path.isfile(CSV_FILE)
    
    # Open the file in append mode
    with open(CSV_FILE, 'a', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=["title", "price", "link", "scraped_at"])
        
        # Write the header only if the file does not exist
        if not file_exists:
            writer.writeheader()
        
        # Write the data with a timestamp
        for item in data:
            item['scraped_at'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            writer.writerow(item)
    
    print(f"[INFO] Data saved to {CSV_FILE}")

# Main function to manage Apify task and Playwright scraping
async def main():
    print("[INFO] Starting the Apify task and scraping process...")
    # Initialize ApifyClient with your API token
    client = ApifyClient("apify_api_VbRrfnRWdV6ww6OmwN615wkCucolSP41Ws2M")

    # Start the actor task
    run = client.task("Y7zA7bSIvbroUL9Cx").call()

    # Use Playwright's async context manager to handle setup and teardown
    async with async_playwright() as playwright:
        # Run the scraping task
        data = await run_scraping(playwright)

    # Print the scraped data (or handle it as needed)
    print("[INFO] Scraping completed.")
    print("Scraped Data:", data)

    # Save the scraped data to a CSV file
    save_to_csv(data)
    print("[INFO] Task completed.")

# Function to run the main script
def run_script():
    print("[INFO] Running scheduled scraping task...")
    asyncio.run(main())

# Schedule the script to run 4 times a day
schedule.every(6).hours.do(run_script)

# Keep the script running to maintain the schedule
while True:
    print(f"[INFO] Waiting for the next scheduled task...")
    schedule.run_pending()
    time.sleep(1)

# Entry point for the script
if __name__ == "__main__":
    run_script()
