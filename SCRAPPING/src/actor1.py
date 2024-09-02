import asyncio
from playwright.async_api import (
    async_playwright,
)  # Import Playwright's async API for browser automation
from apify_client import (
    ApifyClient,
)  # Import ApifyClient if you plan to integrate with Apify (optional)


# Function to extract data from the page
async def extract_data(page):
    """
    Extracts listings data from the page.

    This function uses the `page.evaluate` method to run JavaScript code within the browser context,
    fetching data such as title, price, and link for each listing on the page.

    Args:
        page: The Playwright page object representing the current browser tab.

    Returns:
        A list of dictionaries, each representing a listing with 'title', 'price', and 'link'.
    """
    listings = await page.evaluate(
        """() => {
        return Array.from(document.querySelectorAll('.listing')).map(listing => ({
            title: listing.querySelector('.title').innerText,
            price: listing.querySelector('.price').innerText,
            link: listing.querySelector('a').href,
        }));
    }"""
    )
    return listings


# Function to handle the browsing and scraping logic
async def run(playwright):
    """
    Launches a browser instance, opens a new page, and navigates to the target URL.

    This function performs the main scraping task, which includes:
    - Launching a browser.
    - Creating a new browser context (essentially a new session).
    - Opening a new page (tab) and navigating to the target URL.
    - Extracting data from the page using the `extract_data` function.
    - Closing the browser once done.

    Args:
        playwright: The Playwright object to control the browser.
    """
    # Launch a headless browser (without a UI)
    browser = await playwright.chromium.launch(headless=True)
    # Create a new browser context (isolated session)
    context = await browser.new_context()
    # Open a new tab/page in the browser
    page = await context.new_page()

    # Navigate to the target URL (replace with the URL of the town's rental listings)
    await page.goto("https://www.airbnb.com/s/small-town/homes")

    # Extract data from the page
    data = await extract_data(page)
    print(data)  # Print the extracted data (you can save this data instead of printing)

    # Close the browser once scraping is complete
    await browser.close()


# Main function to manage asynchronous execution
async def main():
    """
    The main entry point for the script.

    This function initializes Playwright and runs the scraping logic.
    It is wrapped in an asyncio event loop to handle asynchronous tasks.
    """
    # Use Playwright's async context manager to handle setup and teardown
    async with async_playwright() as playwright:
        await run(playwright)


# Entry point for the script
if __name__ == "__main__":
    """
    When the script is executed directly, this block will run.

    It starts the asyncio event loop and runs the main function, ensuring that all asynchronous
    operations are handled correctly.
    """
    asyncio.run(main())  # Run the main function using asyncio's event loop
