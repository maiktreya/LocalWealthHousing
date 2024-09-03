# Spain-Rental Prices Scrapper for RbnB by @Tlaloc 03092024
import asyncio
import csv
import os
from playwright.async_api import async_playwright
from apify_client import ApifyClient

CSV_FILE = "scraped_data.csv"


async def extract_data(page):
    try:
        listings = await page.evaluate(
            """() => {
            return Array.from(document.querySelectorAll("[data-testid='property-card']")).map(listing => ({
                title: listing.querySelector("[data-testid='listing-name']").innerText || "N/A",
                price: listing.querySelector("[data-testid='listing-price']").innerText || "N/A",
                link: listing.querySelector("a").href || "N/A",
            }));
        }"""
        )
        return listings
    except Exception as e:
        print(f"Error extracting data: {e}")
        return []


async def run_scraping(playwright):
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context()
    page = await context.new_page()

    await page.goto("https://www.airbnb.com/s/small-town/homes")

    data = await extract_data(page)
    await browser.close()
    return data


def save_to_csv(data):
    if not data:
        print("No data found to save.")
        return

    file_exists = os.path.isfile(CSV_FILE)

    with open(CSV_FILE, "a", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=["title", "price", "link"])

        if not file_exists:
            writer.writeheader()

        writer.writerows(data)

    print(f"Data saved to {CSV_FILE}")


async def main():
    client = ApifyClient("apify_api_VbRrfnRWdV6ww6OmwN615wkCucolSP41Ws2M")

    run = client.task("Y7zA7bSIvbroUL9Cx").call()

    async with async_playwright() as playwright:
        data = await run_scraping(playwright)

    if data:
        print(f"Scraped {len(data)} listings")
        save_to_csv(data)
    else:
        print("No data scraped.")


if __name__ == "__main__":
    asyncio.run(main())
