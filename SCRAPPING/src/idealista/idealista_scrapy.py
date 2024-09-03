import scrapy

class IdealistaSpider(scrapy.Spider):
    name = "idealista"
    start_urls = ['https://www.idealista.com/en/venta-viviendas/madrid-madrid/']

    def parse(self, response):
        for property in response.css('article.item'):
            yield {
                'title': property.css('a.item-link::text').get(),
                'price': property.css('span.item-price::text').get(),
                'link': property.css('a.item-link::attr(href)').get(),
            }
# to run: scrapy runspider idealista_spider.py -o properties.csv
