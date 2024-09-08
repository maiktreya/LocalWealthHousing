#!/bin/bash
# Activate virtual environment
source /home/other/dev/github/LocalWealthHousing/env/bin/activate

# Run scraper for the first URL
echo "Running scraper for Segovia Sale..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/idealista/idealista_httpx.ori.py --url "https://www.idealista.com/venta-viviendas/segovia-segovia/" --delay 5
echo "Finished scraping Segovia Sale. Waiting 5 minutes..."

# Sleep for 5 minutes (300 seconds)
sleep 300

# Run scraper for the second URL
echo "Running scraper for Segovia Rent..."
/home/other/dev/github/LocalWealthHousing/env/bin/python /home/other/dev/github/LocalWealthHousing/scrapping/src/idealista/idealista_httpx.ori.py --url "https://www.idealista.com/alquiler-viviendas/segovia-segovia/" --delay 5
echo "Finished scraping Segovia Rent."
