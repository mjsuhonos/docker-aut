import csv
import requests
import datetime
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import cycle
from threading import Lock

# Set up argument parsing
parser = argparse.ArgumentParser(description='Process some files.')
parser.add_argument('input_file', type=str, help='Input CSV file')
parser.add_argument('output_file', type=str, help='Output CSV file')

# Parse arguments
args = parser.parse_args()

# Assign variables from arguments
input_file = args.input_file
output_file = args.output_file

# Initialize the lock at the beginning of your main function or as a global variable
write_lock = Lock()
session = requests.Session()  # Create a session object

# List of N different API URLs
api_urls = [
    'http://localhost:5001/v1/projects/u1-broader-e-arch0-en/suggest-batch',
    'http://localhost:5002/v1/projects/u1-broader-e-arch0-en/suggest-batch',
    'http://localhost:5003/v1/projects/u1-broader-e-arch0-en/suggest-batch',
    'http://localhost:5004/v1/projects/u1-broader-e-arch0-en/suggest-batch',
    'http://localhost:5005/v1/projects/u1-broader-e-arch0-en/suggest-batch',
    'http://localhost:5006/v1/projects/u1-broader-e-arch0-en/suggest-batch',
]

def send_request(batch, url):
    data = {
        "documents": [{"text": text, "document_id": hash_value} for hash_value, text in batch],
        'limit': 5
    }
    # This is the slowest step
    response = session.post(url, json=data)  # Use the session to send the request
    return response

def process_response(batch_start, response, csv_writer):
    with write_lock:  # This will acquire the lock before entering the block and release it after
        if response.status_code == 200:
            batch_suggestions = response.json()
            for document_suggestions in batch_suggestions:
                hash_value = document_suggestions['document_id']
                for suggestion in document_suggestions['results']:
                    qid = suggestion['uri'].split('/')[-1]
                    score = suggestion['score']
                    suggest_date = datetime.datetime.now().strftime('%y%m%d%H%M%S')
                    csv_writer.writerow([hash_value, qid, score, suggest_date])
            print(f"Suggested batch starting with row {batch_start}")
        else:
            print(f"Error with batch starting at row {batch_start}: {response.status_code}")

def main():
    batch_size = 32  # Number of documents to send to each API (max 32)
    N = len(api_urls)  # Number of threads equals the number of API URLs
    
    with open(input_file, newline='') as csvfile:
        csv_reader = csv.reader(csvfile)
        rows = [(row[0], row[1]) for row in csv_reader if row]  # Create a list of tuples

    print(f"Reading from {input_file}...")

    with open(output_file, mode='a', newline='') as csv_file, ThreadPoolExecutor(max_workers=N) as executor:
        csv_writer = csv.writer(csv_file)
        url_cycle = cycle(api_urls)  # Create an iterator that cycles through the URLs

        future_to_batch_start = {}
        for batch_start in range(0, len(rows), batch_size):
            url = next(url_cycle)  # Get the next URL from the cycle
            batch = rows[batch_start:batch_start + batch_size]
            future = executor.submit(send_request, batch, url)
            future_to_batch_start[future] = batch_start

        for future in as_completed(future_to_batch_start):
            batch_start = future_to_batch_start[future]
            try:
                response = future.result()
                process_response(batch_start, response, csv_writer)
            except Exception as e:
                print(f"Exception for batch starting at row {batch_start}: {e}")

    print(f"Created {output_file}!")

if __name__ == "__main__":
    main()