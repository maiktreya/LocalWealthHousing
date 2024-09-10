## Example implementation of scrapy for idealista.com

Scrapping a webpago (Static html) with pagination

1. Init proejct

> scrapy startproject idealista

2. Move to project folder

> cd idealista

3. Create spider

> scrapy genspider idealista idealista.com

4. Run spider
> scrapy crawl idealista -t csv -o aa.csv


For debugging run:
scrapy parse --spider=idealista --loglevel=DEBUG -c parse_flats "URL"