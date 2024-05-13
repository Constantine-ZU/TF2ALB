import requests
import os

# Получение переменных окружения
api_token = os.getenv("HETZNER_DNS_KEY")
new_ip = os.getenv("NEW_IP")
record_name = os.getenv("HETZNER_RECORD_NAME")
domain_name = os.getenv("HETZNER_DOMAIN_NAME")

print(f"New IP: {new_ip}")
print(f"Record Name: {record_name}")
print(f"Domain Name: {domain_name}")
print(f"API Key (first 5 chars): {api_token[:5]}...")

# Заголовки для API запросов
headers = {
    "Content-Type": "application/json",
    "Auth-API-Token": api_token
}

# Получение Zone ID
def get_zone_id(domain_name):
    url = "https://dns.hetzner.com/api/v1/zones"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        zones = response.json()['zones']
        for zone in zones:
            if domain_name in zone['name']:
                return zone['id']
    return None

# Получение Record ID
def get_record_id(zone_id, record_name):
    url = f"https://dns.hetzner.com/api/v1/records?zone_id={zone_id}"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        records = response.json()['records']
        for record in records:
            if record['name'] == record_name and record['type'] == 'A':
                return record['id']
    return None

# Основной процесс обновления
zone_id = get_zone_id(domain_name)
if zone_id:
    print(f"Zone ID: {zone_id}")
    record_id = get_record_id(zone_id, record_name)
    if record_id:
        print(f"Record ID: {record_id}")
        # Обновление A-записи
        url = f"https://dns.hetzner.com/api/v1/records/{record_id}"
        data = {
            "value": new_ip,
            "ttl": 60,
            "type": "A",
            "name": record_name,
            "zone_id": zone_id
        }
        response = requests.put(url, headers=headers, json=data)
        if response.status_code == 200:
            print(f"Successfully updated A record {record_name} to {new_ip}")
        else:
            print(f"Failed to update A record: {response.status_code}, {response.text}")
    else:
        print(f"No record ID found for {record_name}.")
else:
    print(f"No zone ID found for {domain_name}.")
