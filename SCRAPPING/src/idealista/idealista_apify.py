import requests
from bs4 import BeautifulSoup

url = 'https://www.idealista.com/en/venta-viviendas/madrid-madrid/'

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
}

response = requests.get(url, headers=headers)
soup = BeautifulSoup(response.content, 'html.parser')

# Example: Extracting titles of property listings
titles = soup.find_all('a', class_='item-link')
for title in titles:
    print(title.get_text(strip=True))
