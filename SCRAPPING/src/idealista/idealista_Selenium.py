from selenium import webdriver
from selenium.webdriver.common.by import By

url = 'https://www.idealista.com/en/venta-viviendas/madrid-madrid/'

driver = webdriver.Chrome()  # Make sure to have ChromeDriver installed and in your PATH
driver.get(url)

# Example: Extracting titles of property listings
titles = driver.find_elements(By.CLASS_NAME, 'item-link')
for title in titles:
    print(title.text)

driver.quit()
