from apify_client import ApifyClient

# Initialize the ApifyClient with your API token
client = ApifyClient("apify_api_VbRrfnRWdV6ww6OmwN615wkCucolSP41Ws2M")

# Run the Actor task and wait for it to finish
run = client.task("Y7zA7bSIvbroUL9Cx").call()

# Fetch and print Actor task results from the run's dataset (if there are any)
for item in client.dataset(run["defaultDatasetId"]).iterate_items():
    print(item)