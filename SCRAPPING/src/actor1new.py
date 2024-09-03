import asyncio
import csv
import os
from playwright.async_api import async_playwright  # Playwright for web scraping
from apify_client import ApifyClient  # ApifyClient for interacting with Apify API

CSV_FILE = "scraped_data.csv"

# Function to extract data from the page
async def extract_data(page):
    listings = await page.evaluate(
        '''() => {
        return Array.from(document.querySelectorAll(".listing")).map(listing => ({
            title: listing.querySelector(".title").innerText,
            price: listing.querySelector(".price").innerText,
            link: listing.querySelector("a").href,
        }));
    }'''
    )
    return listings

# Function to handle the browsing and scraping logic
async def run_scraping(playwright):
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context()
    page = await context.new_page()

    # Navigate to the target URL
    await page.goto("https://www.airbnb.com/s/small-town/homes")

    # Extract data from the page
    data = await extract_data(page)
    await browser.close()
    return data

# Function to handle data saving to CSV
def save_to_csv(data):
    # Check if the file exists
    file_exists = os.path.isfile(CSV_FILE)
    
    # Open the file in append mode
    with open(CSV_FILE, 'a', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=["title", "price", "link"])
        
        # Write the header only if the file does not exist
        if not file_exists:
            writer.writeheader()
        
        # Write the data to the CSV file
        writer.writerows(data)

# Main function to manage Apify task and Playwright scraping
async def main():
    # Initialize ApifyClient with your API token
    client = ApifyClient("apify_api_VbRrfnRWdV6ww6OmwN615wkCucolSP41Ws2M")

    # Start the actor task
    run = client.task("Y7zA7bSIvbroUL9Cx").call()

    # Use Playwright's async context manager to handle setup and teardown
    async with async_playwright() as playwright:
        # Run the scraping task
        data = await run_scraping(playwright)

    # Print the scraped data (or handle it as needed)
    print("Scraped Data:", data)

    # Save the scraped data to a CSV file
    save_to_csv(data)

# Entry point for the script
if __name__ == "__main__":
    asyncio.run(main())
