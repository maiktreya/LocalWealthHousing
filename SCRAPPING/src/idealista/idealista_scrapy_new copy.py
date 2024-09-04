import asyncio
import json
import re
from typing import Dict, List
from collections import defaultdict
from urllib.parse import urljoin
import httpx
from parsel import Selector
from typing_extensions import TypedDict
import csv
from datetime import datetime

# Establish persistent HTTPX session with browser-like headers to avoid blocking
BASE_HEADERS = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "accept-language": "en-US;en;q=0.9",
    "accept-encoding": "gzip, deflate, br",
}
session = httpx.AsyncClient(headers=BASE_HEADERS, follow_redirects=True, timeout=10.0)


# Type hints for expected results so we can visualize our scraper easier:
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

    # Convert the price string to an integer after removing non-numeric characters
    price_str = css(".info-data-price span::text")
    if price_str:
        price_str = price_str.replace(".", "").replace(",", "")
        data["price"] = int(price_str)
    else:
        data["price"] = None  # Handle cases where the price might not be available

    data["description"] = "\n".join(css_all("div.comment ::text")).strip()
    data["updated"] = (
        selector.xpath("//p[@class='stats-text'][contains(text(),'updated on')]/text()")
        .get("")
        .split(" on ")[-1]
    )

    # Features
    data["features"] = {}
    for feature_block in selector.css(".details-property-h2"):
        label = feature_block.xpath("text()").get()
        features = feature_block.xpath("following-sibling::div[1]//li")
        data["features"][label] = [
            "".join(feat.xpath(".//text()").getall()).strip() for feat in features
        ]

    # Images
    image_data = re.findall(r"fullScreenGalleryPics\s*:\s*(\[.+?\]),", response.text)[0]
    images = json.loads(re.sub(r"(\w+?):([^/])", r'"\1":\2', image_data))
    data["images"] = defaultdict(list)
    data["plans"] = []
    for image in images:
        url = urljoin(str(response.url), image["imageUrl"])
        if image["isPlan"]:
            data["plans"].append(url)
        else:
            data["images"][image["tag"]].append(url)
    return data


async def extract_property_urls(area_url: str) -> List[str]:
    """Extract property URLs from an area page, handling pagination"""
    all_property_urls = []
    current_page = 1
    while True:
        page_url = f"{area_url}?pagina={current_page}"
        response = await session.get(page_url)
        selector = Selector(text=response.text)

        property_links = selector.css("article.item a.item-link::attr(href)").getall()
        if not property_links:
            break  # No more properties found on this page

        full_urls = [urljoin(area_url, link) for link in property_links]
        all_property_urls.extend(full_urls)

        current_page += 1

    return all_property_urls


async def scrape_properties(urls: List[str]) -> List[PropertyResult]:
    """Scrape Idealista.com properties"""
    properties = []
    for url in urls:
        for attempt in range(3):  # Retry up to 3 times
            try:
                response = await session.get(url)
                print(response.status_code)
                if response.status_code == 200:
                    properties.append(parse_property(response))
                else:
                    print(
                        f"Failed to scrape property: {response.url} with status code {response.status_code}"
                    )
                break  # If successful, exit the retry loop
            except (httpx.ReadTimeout, httpx.RequestError) as e:
                print(f"Attempt {attempt + 1} failed for URL: {url}, Error: {str(e)}")
                if attempt == 2:
                    print(f"Failed to retrieve URL: {url} after 3 attempts")
    return properties


def save_to_json(data: List[PropertyResult], filename: str) -> None:
    """Save data to a JSON file"""
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def save_to_csv(data: List[PropertyResult], filename: str) -> None:
    """Save data to a CSV file, flattening nested structures"""
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'url',
            'title',
            'location',
            'price',
            'currency',
            'description',
            'updated',
            'features_flat',
            'images_flat',
            'plans_flat',
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for property in data:
            features_flat = ', '.join([f'{k}: {v}' for k, v in property['features'].items() for v in v])
            images_flat = ', '.join(property['images'].get('main', []))
            plans_flat = ', '.join(property['plans'])
            writer.writerow({
                'url': property['url'],
                'title': property['title'],
                'location': property['location'],
                'price': property['price'],
                'currency': property['currency'],
                'description': property['description'],
                'updated': property['updated'],
                'features_flat': features_flat,
                'images_flat': images_flat,
                'plans_flat': plans_flat,
            })


async def run():
    area_url = "https://www.idealista.com/alquiler-viviendas/segovia-segovia/"
    property_urls = await extract_property_urls(area_url)
    data = await scrape_properties(property_urls)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    json_filename = f"idealista_properties_{timestamp}.json"
    csv_filename = f"idealista_properties_{timestamp}.csv"

    save_to_json(data, json_filename)
    save_to_csv(data, csv_filename)

    print(f"Data saved to {json_filename} and {csv_filename}")


if __name__ == "__main__":
    asyncio.run(run())
