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

# type hints fo expected results so we can visualize our scraper easier:
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
    """parse Idealista.com property page"""
    selector = Selector(text=response.text)
    css = lambda x: selector.css(x).get("").strip()
    css_all = lambda x: selector.css(x).getall()

    data = {}
    data["url"] = str(response.url)
    data['title'] = css("h1 .main-info__title-main::text")
    data['location'] = css(".main-info__title-minor::text")
    data['currency'] = css(".info-data-price::text")
    data['price'] = int(css(".info-data-price span::text").replace(",", ""))
    data['description'] = "\n".join(css_all("div.comment ::text")).strip()
    data["updated"] = selector.xpath("//p[@class='stats-text'][contains(text(),'updated on')]/text()").get("").split(" on ")[-1]

    data["features"] = {}
    for feature_block in selector.css(".details-property-h2"):
        label = feature_block.xpath("text()").get()
        features = feature_block.xpath("following-sibling::div[1]//li")
        data["features"][label] = [''.join(feat.xpath(".//text()").getall()).strip() for feat in features]

    image_data = re.findall(r"fullScreenGalleryPics\s*:\s*(\[.+?\]),", response.text)[0]
    images = json.loads(re.sub(r'(\w+?):([^/])', r'"\1":\2', image_data))
    data['images'] = defaultdict(list)
    data['plans'] = []
    for image in images:
        url = urljoin(str(response.url), image['imageUrl'])
        if image['isPlan']:
            data['plans'].append(url)
        else:
            data['images'][image['tag']].append(url)
    return data


async def scrape_properties(urls: List[str]) -> List[PropertyResult]:
    """Scrape Idealista.com properties"""
    properties = []
    to_scrape = [session.get(url) for url in urls]
    for response in asyncio.as_completed(to_scrape):
        response = await response
        print(response.status_code)
        if response.status_code != 200:
            print(f"can't scrape property: {response.url}")
            continue
        properties.append(parse_property(response))
    return properties    

def parse_province(response: httpx.Response) -> List[str]:
    """parse province page for area search urls"""
    selector = Selector(text=response.text)
    urls = selector.css("#location_list li>a::attr(href)").getall()
    return [urljoin(str(response.url), url) for url in urls]

async def paginate(url: str) -> List[str]:
    """Recursively follow pagination links and collect all page URLs"""
    search_urls = []
    while url:
        response = await session.get(url)
        if response.status_code != 200:
            print(f"Failed to scrape: {url}")
            break
        search_urls.extend(parse_province(response))
        
        # Look for the 'next' page link and continue scraping if found
        selector = Selector(text=response.text)
        next_page = selector.css("a.icon-arrow-right::attr(href)").get()
        if next_page:
            url = urljoin(url, next_page)
        else:
            url = None  # No more pages

    return search_urls

async def scrape_provinces(urls: List[str]) -> List[str]:
    """Scrape province pages and follow pagination"""
    search_urls = []
    for url in urls:
        search_urls.extend(await paginate(url))
    return search_urls  

async def run():
    data = await scrape_provinces([
             "https://www.idealista.com/alquiler-viviendas/segovia-segovia/"
    ])
    print(json.dumps(data, indent=2))

if __name__ == "__main__":
    asyncio.run(run())
