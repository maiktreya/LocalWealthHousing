#!/bin/bash

# Activate virtual environment
source /home/other/dev/github/LocalWealthHousing/env/bin/activate

# Run Airbnb scrapers
echo "Running Airbnb Short-Term Scraper..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/airbnb/airbnb_apify_short.py && \
echo "Airbnb Short-Term Scraper finished. Running Medium-Term Scraper..."

echo "Running Airbnb Medium-Term Scraper..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/airbnb/airbnb_apify_medium.py && \
echo "Airbnb Medium-Term Scraper finished. Running Long-Term Scraper..."

echo "Running Airbnb Long-Term Scraper..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/airbnb/airbnb_apify_long.py
echo "Airbnb Long-Term Scraper finished."

# Now run Idealista scrapers
echo "Running Idealista Segovia Sale Scraper..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/idealista/idealista_httpx.ori.py --url "https://www.idealista.com/venta-viviendas/segovia-segovia/" --delay 5
echo "Finished scraping Segovia Sale. Waiting 5 minutes..."

# Sleep for 5 minutes (300 seconds)
sleep 300

# Run scraper for the second URL
echo "Running Idealista Segovia Rent Scraper..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/idealista/idealista_httpx.ori.py --url "https://www.idealista.com/alquiler-viviendas/segovia-segovia/" --delay 5
echo "Finished scraping Segovia Rent."
