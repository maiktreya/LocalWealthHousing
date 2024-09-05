import scrapy


class IdealistatestSpider(scrapy.Spider):
    name = "idealistaTest"
    allowed_domains = ["idealista.com"]
    start_urls = ["https://idealista.com"]

    def parse(self, response):
        pass
