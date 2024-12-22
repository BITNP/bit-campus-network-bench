#!/usr/bin/env python3

import time
import argparse
from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions
from tqdm import tqdm
import json


def get_test_target() -> list[dict]:
    "get test target site from BIT library"
    try:
        with open("db_list_output.json") as f:
            return json.loads(f.read())
    except:
        print("plz run get-library-database.py")
        exit(0)


def get_driver(browser: str) -> webdriver.remote.webdriver.WebDriver:
    "get browser driver, set proxy"
    if browser == 'firefox':
        options = FirefoxOptions()
        options.headless = True
        return webdriver.Firefox(options=options)
    else:
        options = ChromeOptions()
        options.headless = True
        return webdriver.Chrome(options=options)


def do_test_single(browser: webdriver.remote.webdriver.WebDriver, url: dict):
    "open a single page, print the time"
    start_time = time.time()
    browser.get(url["url"])
    used_time = time.time() - start_time
    tqdm.write(f"{url["name"]} {url["url"]} load finish in {used_time}s")
    return url["name"], url["url"], used_time


def do_test_all(browser: webdriver.remote.webdriver.WebDriver, urls: list[dict]):
    "test all urls"
    test_results = []
    for url in tqdm(urls):
        test_results.append(do_test_single(browser, url))
    return test_results


def main():
    "main program"
    parser = argparse.ArgumentParser()
    parser.add_argument('browser', choices=['chrome', 'firefox'])
    args = parser.parse_args()
    urls = get_test_target()
    with get_driver(args.browser) as driver:
        test_results = do_test_all(driver, urls)
        with open("library_results.txt", "w") as f:
            f.writelines((repr(result) for result in test_results))


if __name__ == '__main__':
    main()
