# example from https://blog.apify.com/web-scraping-python/
import httpx
from bs4 import BeautifulSoup

# Function to get HTML content from a URL
def get_html_content(url: str, timeout: int = 10) -> str:
    response = httpx.get(url, timeout=timeout)
    return str(response.text)

# Function to parse a single article
def parse_article(article) -> dict:
    url = article.find(class_='titleline').find('a').get('href')
    title = article.find(class_='titleline').get_text()
    rank = article.find(class_='rank').get_text().replace('.', '')
    return {'url': url, 'title': title, 'rank': rank}

# Function to parse all articles in the HTML content
def parse_html_content(html: str) -> list:
    soup = BeautifulSoup(html, features='html.parser')
    articles = soup.find_all(class_='athing')
    return [parse_article(article) for article in articles]

# Main function to get and parse HTML content
def main() -> None:
    html_content = get_html_content('https://news.ycombinator.com')
    data = parse_html_content(html_content)
    print(data)

if __name__ == '__main__':
    main()


# Expected Output:
'''
[
   {
      "url":"https://ian.sh/tsa",
      "title":"Bypassing airport security via SQL injection (ian.sh)",
      "rank":"1"
   },
   {
      "url":"https://www.elastic.co/blog/elasticsearch-is-open-source-again",
      "title":"Elasticsearch is open source, again (elastic.co)",
      "rank":"2"
   },
     ...
   {
      "url":"https://languagelog.ldc.upenn.edu/nll/?p=73",
      "title":"Two Dots Too Many (2008) (upenn.edu)",
      "rank":"29"
   },
   {
      "url":"https://collidingscopes.github.io/ascii/",
      "title":"Show HN: turn videos into ASCII art (open source, js+canvas) (collidingscopes.github.io)",
      "rank":"30"
   }
]
'''
