import csv
import aiohttp
import asyncio
import datetime
import argparse
import random
from itertools import cycle

# Set up argument parsing
parser = argparse.ArgumentParser(description='Process some files.')
parser.add_argument('input_file', type=str, help='Input CSV file')
parser.add_argument('output_file', type=str, help='Output CSV file')
args = parser.parse_args()

# Assign variables from arguments
input_file = args.input_file
output_file = args.output_file

# List of N different API URLs
api_urls = [
    'http://localhost:5001/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://localhost:5002/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://localhost:5003/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://localhost:5004/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://localhost:5005/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://localhost:5006/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5001/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5002/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5003/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5004/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5005/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
    'http://10.137.64.230:5006/v1/projects/u1-broader-e-arch0-en/suggest-batch?limit=5',
]
random.shuffle(api_urls)

async def send_request(session, batch, url):
    data = {
        "documents": [{"text": text, "document_id": hash_value} for hash_value, text in batch]
    }
    # This is the slowest step
    async with session.post(url, json=data) as response:
        return await response.json(), response.status

def process_response(batch_start, batch_suggestions, status_code, csv_writer):
    if status_code == 200:
        for document_suggestions in batch_suggestions:
            hash_value = document_suggestions['document_id']
            for suggestion in document_suggestions['results']:
                qid = suggestion['uri'].split('/')[-1]
                score = suggestion['score']
                suggest_date = datetime.datetime.now().strftime('%y%m%d%H%M%S')
                csv_writer.writerow([hash_value, qid, score, suggest_date])
        print(f"Suggested batch starting with row {batch_start}")
    else:
        print(f"Error with batch starting at row {batch_start}: {status_code}")

async def main():
    batch_size = 32 # Number of documents to send to each API (max 32)
    processed_hashes = set()

    # Skip already-processed hashes
    try:
        with open(output_file, mode='r', newline='') as csv_file:
            csv_reader = csv.reader(csv_file)
            processed_hashes = {row[0] for row in csv_reader if row}
            print(f"Skipping {len(processed_hashes)}...")
    except FileNotFoundError:
        pass # It's okay if the file doesn't exist yet

    # Read input file and prepare rows
    print(f"Reading from {input_file}...")
    with open(input_file, newline='') as csvfile:
        csv_reader = csv.reader(csvfile)
        rows = [(row[0], row[1]) for row in csv_reader if row and row[0] not in processed_hashes]

    # Write to output file
    with open(output_file, mode='a', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        url_cycle = cycle(api_urls)

        async with aiohttp.ClientSession() as session:
            tasks = []
            for batch_start in range(0, len(rows), batch_size):
                url = next(url_cycle)
                batch = rows[batch_start:batch_start + batch_size]
                task = asyncio.ensure_future(send_request(session, batch, url))
                tasks.append((task, batch_start))

            responses = await asyncio.gather(*[t[0] for t in tasks])

            for response, (task, batch_start) in zip(responses, tasks):
                batch_suggestions, status_code = response
                process_response(batch_start, batch_suggestions, status_code, csv_writer)

    print(f"Created {output_file}!")

if __name__ == "__main__":
    asyncio.run(main())
