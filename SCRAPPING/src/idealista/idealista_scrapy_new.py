import asyncio
import json
import re
from typing import Dict, List
from collections import defaultdict
from urllib.parse import urljoin
import httpx
from parsel import Selector
from typing_extensions import TypedDict

# Establish persistent HTTPX session with browser-like headers to avoid blocking
BASE_HEADERS = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "accept-language": "en-US;en;q=0.9",
    "accept-encoding": "gzip, deflate, br",
}
session = httpx.AsyncClient(headers=BASE_HEADERS, follow_redirects=True)

# Type hints for expected results so we can visualize our scraper easier
class PropertyResult(TypedDict):
    url: str
    title: str
    location: str
    price: int
    currency: str
    description: str
    updated: str
    features: Dict[str, List[str]]
    images: Dict[str, List[str]]
    plans: List[str]


def parse_property(response: httpx.Response) -> PropertyResult:
    """Parse Idealista.com property page"""
    # Load response's HTML tree for parsing
    selector = Selector(text=response.text)
    css = lambda x: selector.css(x).get("").strip()
    css_all = lambda x: selector.css(x).getall()

    data = {}
    # Meta data
    data["url"] = str(response.url)

    # Basic information
    data["title"] = css("h1 .main-info__title-main::text")
    data["location"] = css(".main-info__title-minor::text")
    data["currency"] = css(".info-data-price::text")
    data["price"] = int(css(".info-data-price span::text").replace(",", ""))
    data["description"] = "\n".join(css_all("div.comment ::text")).strip()
    data["updated"] = selector.xpath(
        "//p[@class='stats-text'][contains(text(),'updated on')]/text()"
    ).get("").split(" on ")[-1]

    # Features
    data["features"] = {}
    # First we extract each feature block like "Basic Features" or "Amenities"
    for feature_block in selector.css(".details-property-h2"):
        # Then for each block we extract all bullet points underneath them
        label = feature_block.xpath("text()").get()
        features = feature_block.xpath("following-sibling::div[1]//li")
        data["features"][label] = [
            ''.join(feat.xpath(".//text()").getall()).strip() for feat in features
        ]

    # Images
    image_data = re.findall(
        r"fullScreenGalleryPics\s*:\s*(\[.+?\]),", response.text
    )[0]
    images = json.loads(re.sub(r'(\w+?):([^/])', r'"\1":\2', image_data))
    data["images"] = defaultdict(list)
    data["plans"] = []
    for image in images:
        url = urljoin(str(response.url), image["imageUrl"])
        if image["isPlan"]:
            data["plans"].append(url)
        else:
            data["images"][image["tag"]].append(url)
    return data


async def scrape_properties(urls: List[str]) -> List[PropertyResult]:
    """Scrape Idealista.com properties"""
    properties = []
    to_scrape = [session.get(url) for url in urls]
    for response in asyncio.as_completed(to_scrape):
        response = await response
        if response.status_code != 200:
            print(f"can't scrape property: {response.url}")
            continue
        properties.append(parse_property(response))
    return properties


async def parse_city(response: httpx.Response) -> List[str]:
    """Parse city page for property URLs and paginate if necessary"""
    selector = Selector(text=response.text)
    urls = selector.css("#location_list li>a::attr(href)").getall()

    # Scrape the URLs of properties
    property_urls = [urljoin(str(response.url), url) for url in urls]

    # Find pagination URLs
    next_page_url = selector.css("a.icon-arrow-right::attr(href)").get()
    if next_page_url:
        next_page_url = urljoin(str(response.url), next_page_url)
        property_urls.extend(await scrape_paginated(next_page_url))

    return property_urls


async def scrape_paginated(url: str) -> List[str]:
    """Recursively scrape paginated property URLs"""
    response = await session.get(url)
    if response.status_code != 200:
        print(f"Failed to scrape page: {url}")
        return []

    selector = Selector(text=response.text)
    urls = selector.css("#location_list li>a::attr(href)").getall()
    urls = [urljoin(str(response.url), url) for url in urls]

    # Check for "next page" link and recursively scrape if it exists
    next_page_url = selector.css("a.icon-arrow-right::attr(href)").get()
    if next_page_url:
        next_page_url = urljoin(str(response.url), next_page_url)
        urls.extend(await scrape_paginated(next_page_url))

    return urls


async def scrape_city_properties(urls: List[str]) -> List[str]:
    """Scrape city pages and handle pagination"""
    to_scrape = [session.get(url) for url in urls]
    search_urls = []
    async for response in asyncio.as_completed(to_scrape):
        search_urls.extend(await parse_city(await response))
    return search_urls


# Modify the run function to target a city-specific URL for Segovia
async def run():
    data = await scrape_city_properties([
        "https://www.idealista.com/en/venta-viviendas/segovia/"  # Replace with the actual city URL for Segovia
    ])
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    asyncio.run(run())
