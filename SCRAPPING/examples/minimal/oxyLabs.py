import requests

API_KEY = 'your_oxylabs_api_key'
base_url = 'https://www.airbnb.com/s/your_city'
api_url = 'https://realtime.oxylabs.io/v1/queries'

payload = {
    "source": "universal",
    "url": base_url,
    "proxy_type": "residential",
    "geo_location": "Spain"
}

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {API_KEY}"
}

response = requests.post(api_url, json=payload, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(data)
else:
    print(f'Error: {response.status_code}')
