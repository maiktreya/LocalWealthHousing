# Spain-Rental Prices Scrapper for RbnB by @Tlaloc 03092024

import csv
import os
from datetime import datetime
from apify_client import ApifyClient

# Initialize the ApifyClient with your API token
client = ApifyClient("apify_api_VbRrfnRWdV6ww6OmwN615wkCucolSP41Ws2M")

# Run the Actor task and wait for it to finish
run = client.task("Y7zA7bSIvbroUL9Cx").call()

# Get the current timestamp to use in the filename
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
csv_filename = f"scraped_data_{timestamp}.csv"

# Define the output directory
output_dir = "SCRAPPING/out"

# Ensure the output directory exists, create if not
os.makedirs(output_dir, exist_ok=True)

# Full path for the output CSV file
csv_filepath = os.path.join(output_dir, csv_filename)

# Fetch items from the dataset
items = list(client.dataset(run["defaultDatasetId"]).iterate_items())

# If there are any items, write them to a CSV file
if items:
    # Dynamically determine the CSV fieldnames from the JSON keys
    fieldnames = set()
    for item in items:
        fieldnames.update(item.keys())

    # Write the data to a CSV file
    with open(csv_filepath, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=sorted(fieldnames))
        writer.writeheader()
        writer.writerows(items)

    print(f"Data has been saved to {csv_filepath}")
else:
    print("No data was scraped.")
