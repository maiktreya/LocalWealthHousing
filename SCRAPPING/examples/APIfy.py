# example from https://blog.apify.com/web-scraping-python/s
import asyncio
import csv
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.firefox.launch(headless=False)
        page = await browser.new_page()
        await page.goto("https://phones.mintmobile.com/")

        # Create a list to hold the scraped data
        data_list = []

        # Wait for the products to load
        await page.wait_for_selector('ul.products > li')

        products = await page.query_selector_all('ul.products > li')

        for product in products: 
            url_element = await product.query_selector('a')
            name_element = await product.query_selector('h2')
            price_element = await product.query_selector('span.price > span.amount')

            if url_element and name_element and price_element:
                data = {
                    "url": await url_element.get_attribute('href'),
                    "name": await name_element.inner_text(),
                    "price": await price_element.inner_text()
                }
                data_list.append(data)

    await browser.close()

    # Save the data to a CSV file
    with open('products.csv', mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["url", "name", "price"])
        writer.writeheader()
        writer.writerows(data_list)

asyncio.run(main())
