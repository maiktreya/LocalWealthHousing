import scrapy
from idealista.items import SellItem


class CoreSpider(scrapy.Spider):
    name = "idealista_spider"
    default_url = "https://www.idealista.com"

    def __init__(self, name, action, item_type, *args, **kwargs):
        super(CoreSpider, self).__init__(*args, **kwargs)

        self.action = action
        self.item_type = item_type
        self.location = name

    def start_requests(self):
        # Initial URL generation based on action, item_type, and location
        start_url = (
            f"{self.default_url}/{self.action}-{self.item_type}/{self.location}/"
        )
        yield scrapy.Request(url=start_url, callback=self.parse)

    def parse(self, response):
        # Parsing the list of flats on the current page
        flat_list = response.xpath('//div[@class="item-info-container"]')
        for flat in flat_list:
            title = flat.xpath("./a/text()").extract_first()

            link = self.default_url + flat.xpath("./a/@href").extract_first()

            price = (
                flat.xpath(
                    './div[@class="row price-row clearfix"]/span[@class="item-price"]/text()'
                )
                .extract_first(default="0")
                .replace(".", "")
            )

            drop_price = (
                flat.xpath(
                    './div[@class="row price-row clearfix"]/span[contains(@class, "item-price-down")]/text()'
                )
                .extract_first(default="0")
                .strip()
                .split(" ")[0]
                .replace(".", "")
            )

            rooms = (
                flat.xpath(
                    "span[@class='item-detail']/small[contains(text(),'hab.')]/../text()"
                )
                .extract_first(default="0")
                .strip()
            )

            m2 = (
                flat.xpath(
                    'span[@class="item-detail"]/small[starts-with(text(),"m")]/../text()'
                )
                .extract_first(default="0")
                .replace(".", "")
                .strip()
            )

            flat_item = SellItem(
                title=title,
                link=link,
                price=int(price) if price else 0,
                drop_price=int(drop_price) if drop_price else 0,
                rooms=int(rooms) if rooms.isdigit() else 0,
                m2=float(m2) if m2 else 0,
            )

            # Go inside the announcement and get more detailed info
            request = scrapy.Request(
                response.urljoin(link), callback=self.parse_flat_details
            )
            request.meta["flat_item"] = flat_item

            yield request

        # Handling pagination (next page)
        next_page = response.xpath(
            '//div[@class="pagination"]//a[@class="icon-arrow-right-after"]/@href'
        ).extract_first()

        if next_page:
            next_page_url = response.urljoin(next_page)
            yield scrapy.Request(next_page_url, callback=self.parse)

    def parse_flat_details(self, response):
        # Getting more details from the flat details page
        flat_item = response.meta["flat_item"]

        details_info = response.xpath('//section[@id="details"]')

        description = details_info.xpath(
            './div[@class="commentsContainer"]//div[@class="adCommentsLanguage expandable"]/text()'
        ).extract_first()

        price_details = details_info.xpath(
            './div[@class="details-block clearfix"]/div/div'
        )
        price_per_m2 = price_details.xpath(
            './p[contains(., "/m")]/text()'
        ).extract_first(default="N/A")

        costs_per_month = price_details.xpath(
            './p[contains(., "/mes")]/text()'
        ).extract_first(default="N/A")

        address = "\n".join(
            response.xpath(
                '//div[@id="mapWrapper"]//div[@id="addressPromo"]/ul/li/text()'
            ).extract()
        )
        addons = details_info.xpath(
            "//ul/li[string-length(text()) > 1]/text()"
        ).extract()

        # Updating the flat item with more details
        flat_item["description"] = description.strip() if description else ""
        flat_item["price_per_m2"] = price_per_m2.strip() if price_per_m2 else "N/A"
        flat_item["costs_per_month"] = (
            costs_per_month.strip() if costs_per_month else "N/A"
        )
        flat_item["address"] = address.strip() if address else ""
        flat_item["addons"] = [addon.strip() for addon in addons]

        yield flat_item
