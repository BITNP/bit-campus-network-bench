#!/usr/bin/env python3
import requests
import json
import time
from tqdm import tqdm

libresource_url = "https://libresource.bit.edu.cn/go?url="
db_list_content = requests.get("https://lib.bit.edu.cn/db/api/newDbsList").content.decode()
db_list = json.loads(db_list_content)["data"]

db_list_output = []

for db in tqdm(db_list):
    db_name = db["dbName"]
    db_id = db["id"]
    db_url_content = requests.get(f"https://lib.bit.edu.cn/db/api/getDbpByDbIdAndType?dbid={db_id}&type=0").content.decode()
    db_url_json = json.loads(db_url_content)
    db_url = db_url_json["data"][0]["dbUrl"]
    if libresource_url in db_url:
        db_url = db_url.removeprefix(libresource_url)
    # drop nlibvpn urls
    if "nlibvpn" in db_url:
        continue
    db_list_output.append({"name":db_name,"url":db_url})
    time.sleep(0.5)

with open("db_list_output.json", "w") as f:
    f.write(json.dumps(db_list_output))
