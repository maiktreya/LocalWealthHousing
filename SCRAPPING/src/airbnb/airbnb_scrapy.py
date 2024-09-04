# Reference chatgpt conversation:
# before starting run: scrapy startproject rental_scraper
#

import scrapy
import json
import re
from collections import defaultdict
from urllib.parse import urljoin
from datetime import datetime
import os

class IdealistaSpider(scrapy.Spider):
    name = "idealista_spider"
    allowed_domains = ["idealista.com"]

    start_urls = [
        "https://www.airbnb.es/s/Segovia--Espa%C3%B1a"
    ]

    def parse(self, response):
        """Extract property URLs from the area page"""
        property_links = response.css("article.item a.item-link::attr(href)").getall()
        for link in property_links:
            full_url = urljoin(response.url, link)
            yield scrapy.Request(full_url, callback=self.parse_property)

    def parse_property(self, response):
        """Parse Idealista.com property page"""
        selector = response

        data = {}
        # Meta data
        data["url"] = response.url

        # Basic information
        data["title"] = selector.css("h1 .main-info__title-main::text").get().strip()
        data["location"] = selector.css(".main-info__title-minor::text").get().strip()
        data["currency"] = selector.css(".info-data-price::text").get().strip()

        # Convert the price string to an integer after removing non-numeric characters
        price_str = selector.css(".info-data-price span::text").get()
        if price_str:
            price_str = price_str.replace(".", "").replace(",", "")
            data["price"] = int(price_str)
        else:
            data["price"] = None  # Handle cases where the price might not be available

        data["description"] = "\n".join(selector.css("div.comment ::text").getall()).strip()
        data["updated"] = selector.xpath("//p[@class='stats-text'][contains(text(),'updated on')]/text()").re_first(r'updated on (.+)')

        # Features
        data["features"] = {}
        for feature_block in selector.css(".details-property-h2"):
            label = feature_block.xpath("text()").get()
            features = feature_block.xpath("following-sibling::div[1]//li")
            data["features"][label] = [
                "".join(feat.xpath(".//text()").getall()).strip() for feat in features
            ]

        # Images
        image_data = re.findall(r"fullScreenGalleryPics\s*:\s*(\[.+?\]),", response.text)
        if image_data:
            images = json.loads(re.sub(r"(\w+?):([^/])", r'"\1":\2', image_data[0]))
            data["images"] = defaultdict(list)
            data["plans"] = []
            for image in images:
                url = urljoin(response.url, image["imageUrl"])
                if image["isPlan"]:
                    data["plans"].append(url)
                else:
                    data["images"][image["tag"]].append(url)

        yield data

    def close(self, reason):
        """Save the collected data to JSON and CSV files at the end of the spider run."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        json_filename = f"idealista_properties_{timestamp}.json"
        csv_filename = f"idealista_properties_{timestamp}.csv"

        output_dir = "SCRAPPING/out"
        os.makedirs(output_dir, exist_ok=True)

        json_filepath = os.path.join(output_dir, json_filename)
        csv_filepath = os.path.join(output_dir, csv_filename)

        with open(json_filepath, 'w', encoding='utf-8') as f:
            json.dump(self.crawler.stats.get_value('item_scraped_count'), f, ensure_ascii=False, indent=2)

        with open(csv_filepath, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                "url",
                "title",
                "location",
                "price",
                "currency",
                "description",
                "updated",
                "features",
                "images",
                "plans",
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for item in self.crawler.stats.get_value('item_scraped_count'):
                writer.writerow(
                    {
                        "url": item["url"],
                        "title": item["title"],
                        "location": item["location"],
                        "price": item["price"],
                        "currency": item["currency"],
                        "description": item["description"],
                        "updated": item["updated"],
                        "features": json.dumps(item["features"], ensure_ascii=False),
                        "images": json.dumps(item["images"], ensure_ascii=False),
                        "plans": json.dumps(item["plans"], ensure_ascii=False),
                    }
                )

        self.log(f"Data saved to {json_filepath} and {csv_filepath}")
