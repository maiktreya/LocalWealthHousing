import requests

API_KEY = 'your_scraperapi_key'
url = 'https://www.airbnb.com/s/your_city'

response = requests.get(f'http://api.scraperapi.com?api_key={API_KEY}&url={url}&render=true')
if response.status_code == 200:
    data = response.json()
    print(data)
else:
    print(f'Error: {response.status_code}')
