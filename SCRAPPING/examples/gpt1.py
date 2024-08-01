import requests

# Define the API endpoint
api_url = "https://api.example.com/data"

# Define headers, including the API key for authentication
headers = {
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "application/json"
}

# Make a GET request to the API
response = requests.get(api_url, headers=headers)

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON response
    data = response.json()
    # Process the data
    print(data)
else:
    print(f"Failed to retrieve data: {response.status_code}")
