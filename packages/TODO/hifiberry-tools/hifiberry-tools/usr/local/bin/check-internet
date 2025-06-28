#!/usr/bin/env python3

import requests
import time
import argparse

def is_service_available(urls, max_wait_time):
    start_time = time.time()
    while True:
        for url in urls:
            try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    print(f"Service is available at {url}.")
                    return True
            except requests.ConnectionError:
                print(f"Service is not available at {url}.")
            except requests.Timeout:
                print(f"Request to {url} timed out.")
            except requests.RequestException as e:
                print(f"An error occurred while checking {url}: {e}.")

            current_time = time.time()
            elapsed_time = current_time - start_time
            if elapsed_time >= max_wait_time:
                print(f"Reached maximum wait time of {max_wait_time} seconds. Stopping attempts.")
                return False
            remaining_time = max_wait_time - elapsed_time
            sleep_time = min(5, remaining_time)
            time.sleep(sleep_time)

if __name__ == "__main__":
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description="Check if an internet service is available.")
    parser.add_argument("urls", nargs="+", help="URLs to check for availability.")
    parser.add_argument("--timeout", type=int, default=60, help="Maximum time to wait in seconds (default: 60).")
    
    args = parser.parse_args()

    # Example usage with multiple URLs and command-line specified timeout
    is_service_available(args.urls, args.timeout)

