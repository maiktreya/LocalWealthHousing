## minimal working apiffy scrapper
import apify_client
import schedule
import time
import sqlite3
import json

# Initialize the Apify client
apify_client_instance = apify_client.ApifyClient('your_apify_token')

# Define the actor ID and the input for the actor
actor_id = 'your_actor_id'  # Replace with your actor ID
run_input = {
    "startUrls": [
        {"url": "https://www.airbnb.com/s/Segovia--Spain"}
    ],
    # Add any other input parameters your actor requires
}

def run_actor():
    # Run the actor
    run = apify_client_instance.actor(actor_id).call(run_input=run_input)

    # Fetch the results from the default dataset
    dataset_id = run['defaultDatasetId']
    dataset_items = apify_client_instance.dataset(dataset_id).list_items().items

    # Process and store the data
    store_data(dataset_items)

def store_data(data):
    conn = sqlite3.connect('rentals.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS rentals (
            id INTEGER PRIMARY KEY,
            platform TEXT,
            location TEXT,
            m2 REAL,
            price REAL,
            vendor TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    for item in data:
        location = item.get('location', 'Segovia')
        m2 = item.get('m2', 0)
        price = item.get('price', 0)
        vendor = item.get('vendor', 'Unknown')
        c.execute('INSERT INTO rentals (platform, location, m2, price, vendor) VALUES (?, ?, ?, ?, ?)',
                  ('Airbnb', location, m2, price, vendor))
    conn.commit()
    conn.close()

# Schedule the actor to run every 6 hours
schedule.every(6).hours.do(run_actor)

# Initial run
run_actor()

# Keep the script running
while True:
    schedule.run_pending()
    time.sleep(1)
