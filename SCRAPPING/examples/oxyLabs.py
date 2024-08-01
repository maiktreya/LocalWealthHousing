## oxylabs example for AirBnB
import requests
import sqlite3
import time

API_KEY = 'your_oxylabs_api_key'
base_url = 'https://www.airbnb.com/s/your_city'
api_url = 'https://realtime.oxylabs.io/v1/queries'

def scrape_data(url):
    payload = {
        "source": "universal",
        "url": url,
        "proxy_type": "residential",
        "geo_location": "Spain"
    }
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    response = requests.post(api_url, json=payload, headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        print(f'Error: {response.status_code}')
        return None

def store_data(data):
    conn = sqlite3.connect('rentals.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS rentals (
            id INTEGER PRIMARY KEY,
            platform TEXT,
            zone TEXT,
            m2 REAL,
            price REAL,
            vendor TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    for item in data:
        c.execute('INSERT INTO rentals (platform, zone, m2, price, vendor) VALUES (?, ?, ?, ?, ?)',
                  (item['platform'], item['zone'], item['m2'], item['price'], item['vendor']))
    conn.commit()
    conn.close()

def main():
    while True:
        data = scrape_data(base_url)
        if data:
            store_data(data)
        time.sleep(3600)  # Scrape every hour

if __name__ == '__main__':
    main()
