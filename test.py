#!/usr/bin/env python3

import time
import argparse
import requests
from bs4 import BeautifulSoup as bs
from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions
from tqdm import tqdm

INDEX_URL = 'http://lib.bit.edu.cn/node/404.jspx'
PROXY = '127.0.0.1:1089'

def get_test_target() -> list[str]:
    "get test target site from BIT library"
    res = requests.get(INDEX_URL)
    soup = bs(res.text, 'html.parser')
    return list(map(lambda x: x.attrs['href'], soup.find('table').find_all('a')))

def get_driver(browser: str) -> webdriver.remote.webdriver.WebDriver:
    "get browser driver, set proxy"
    proxy = {
            'httpProxy': PROXY,
            'ftpProxy': PROXY,
            'sslProxy': PROXY,
            'proxyType': 'MANUAL'
            }
    if browser == 'firefox':
        webdriver.DesiredCapabilities.FIREFOX['proxy'] = proxy
        options = FirefoxOptions()
        options.headless = True
        return webdriver.Firefox(options=options)
    else:
        webdriver.DesiredCapabilities.CHROME['proxy'] = proxy
        options = ChromeOptions()
        options.headless = True
        return webdriver.Chrome(options=options)

def main():
    "main programe"
    parser = argparse.ArgumentParser()
    parser.add_argument('browser', choices=['chrome', 'firefox'])
    args = parser.parse_args()
    urls = get_test_target()
    with get_driver(args.browser) as driver:
        do_test_all(driver, urls)

def do_test_single(browser: webdriver.remote.webdriver.WebDriver, url: str):
    "open a single page, print the time"
    start_time = time.time()
    browser.get(url)
    used_time = time.time() - start_time
    tqdm.write(f"{url} load finish in {used_time}s")

def do_test_all(browser: webdriver.remote.webdriver.WebDriver, urls: list[str]):
    "test all urls"
    for url in tqdm(urls):
        do_test_single(browser, url)

if __name__ == '__main__':
    main()
