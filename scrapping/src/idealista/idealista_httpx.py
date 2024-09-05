import re
import asyncio
import json
import math
from pathlib import Path
from typing import List
from urllib.parse import urljoin

from scrapfly import ScrapeApiResponse, ScrapeConfig, ScrapflyClient

scrapfly = ScrapflyClient(key="YOUR SCRAPFLY KEY", max_concurrency=2)

# -------------------------------------------------
# Property
# -------------------------------------------------
def parse_property(result: ScrapeApiResponse):
    sel = result.selector
    css = lambda x: result.selector.css(x).get("").strip()
    css_all = lambda x: result.selector.css(x).getall()

    data = {}
    # Meta data
    data["url"] = result.context["url"]

    # Basic information
    data['title'] = css("h1 .main-info__title-main::text")
    data['location'] = css(".main-info__title-minor::text")
    data['currency'] = css(".info-data-price::text")
    data['price'] = int(css(".info-data-price span::text").replace(",", ""))
    data['description'] = "\n".join(css_all("div.comment ::text")).strip()
    data["updated"] = sel.xpath(
        "//p[@class='stats-text']"
        "[contains(text(),'updated on')]/text()"
    ).get("").split(" on ")[-1]

    # Features
    data["features"] = {}
    #  first we extract each feature block like "Basic Features" or "Amenities"
    for feature_block in result.selector.css(".details-property-h3"):
        # then for each block we extract all bullet points underneath them
        label = feature_block.xpath("text()").get()
        features = feature_block.xpath("following-sibling::div[1]//li")
        data["features"][label] = [
            ''.join(feat.xpath(".//text()").getall()).strip()
            for feat in features
        ]

    # Images
    # the images are tucked away in a javascript variable.
    # We can use regular expressions to find the variable and parse it as a dictionary:
    image_data = re.findall("fullScreenGalleryPics\s*:\s*(\[.+?\]),", result.content)[0]
    # we also need to replace unquoted keys to quoted keys (i.e. title -> "title"):
    images = json.loads(re.sub(r'(\w+?):([^/])', r'"\1":\2', image_data))
    data['images'] = defaultdict(list)
    data['plans'] = []
    for image in images:
        url = urljoin(result.context['url'], image['imageUrl'])
        if image['isPlan']:
            data['plans'].append(url)
        else:
            data['images'][image['tag']].append(url)
    return data



async def scrape_properties(urls: List[str]):
    to_scrape = [ScrapeConfig(url=url, country="ES", asp=True) for url in urls]
    results = []
    async for result in scrapfly.concurrent_scrape(to_scrape):
        results.append(parse_property(result))
    return results


# -------------------------------------------------
# Search
# -------------------------------------------------
def parse_province(result: ScrapeApiResponse) -> List[str]:
    """parse province page for area search urls"""
    urls = result.selector.css("#location_list li>a::attr(href)").getall()
    return [urljoin(result.context["url"], url) for url in urls]


async def scrape_provinces(urls: List[str]) -> List[str]:
    """
    Scrape province pages like:
    https://www.idealista.com/en/venta-viviendas/malaga-provincia/con-chalets/municipios
    for search page urls like:
    https://www.idealista.com/en/venta-viviendas/marbella-malaga/con-chalets/
    """
    to_scrape = [ScrapeConfig(url, country="US", asp=True) for url in urls]
    search_urls = []
    async for result in scrapfly.concurrent_scrape(to_scrape):
        search_urls.extend(parse_province(result))
    return search_urls


def parse_search(result: ScrapeApiResponse) -> List[str]:
    """Parse search result page for 30 listings"""
    urls = result.selector.css("article.item .item-link::attr(href)").getall()
    return [urljoin(result.context["url"], url) for url in urls]


async def scrape_search(url: str, max_pages: int = 2) -> List[str]:
    """
    Scrape search urls like:
    https://www.idealista.com/en/venta-viviendas/marbella-malaga/con-chalets/
    for proprety urls
    """
    first_page = await scrapfly.async_scrape(ScrapeConfig(url=url, country="ES", asp=True))
    property_urls = parse_search(first_page)
    if not paginate:
        return property_urls

    total_results = first_page.selector.css("h1#h1-container").re(": (.+) houses")[0]
    total_pages = math.ceil(int(total_results.replace(",", "")) / 30)
    if total_pages > max_pages:  # note idealista allows max 60 pages per search
        print(f"search contains more than max page limit ({total_pages}/60)")
        total_pages = max_pages 
    print(f"scraping {total_pages} of search results concurrently")
    to_scrape = [
        ScrapeConfig(
            url=first_page.context["url"] + f"pagina-{page}.htm",
            asp=True,
            country="ES",
        )
        for page in range(2, total_pages + 1)
    ]
    async for result in scrapfly.concurrent_scrape(to_scrape):
        property_urls.extend(parse_search(result))
    return property_urls


# -------------------------------------------------
# Track Search
# -------------------------------------------------
async def track_search(url: str, output: Path, interval=60):
    """Track Idealista.com results page, scrape new listings and append them as JSON to the output file"""
    seen = set()
    output.touch(exist_ok=True)
    try:
        while True:
            properties = await scrape_search(url=url, paginate=False)
            # check deduplication filter
            properties = [prop for prop in properties if prop not in seen]
            if properties:
                # scrape properties and save to file - 1 property as JSON per line
                results = await scrape_properties(properties)
                with output.open("a") as f:
                    f.write("\n".join(json.dumps(property) for property in results))

                # add seen to deduplication filter
                for prop in properties:
                    seen.add(prop)
            print(f"scraped {len(results)} new properties; waiting {interval} seconds")
            await asyncio.sleep(interval)
    except KeyboardInterrupt:
        print("stopping price tracking")


async def run():
    # scrape properties:
    urls = ["https://www.idealista.com/en/inmueble/97028172/"]
    result_properties = await scrape_properties(urls)
    # find properties
    result_search = await scrape_search("https://www.idealista.com/en/venta-viviendas/marbella-malaga/con-chalets/")
    result_province = await scrape_provinces(["https://www.idealista.com/en/venta-viviendas/balears-illes/con-chalets/municipios"])
    # track properties
    await track_search(
        "https://www.idealista.com/en/venta-viviendas/barcelona/eixample/?ordenado-por=fecha-publicacion-desc",
        Path("new-properties.jsonl"),
    )


if __name__ == "__main__":
    asyncio.run(run())
