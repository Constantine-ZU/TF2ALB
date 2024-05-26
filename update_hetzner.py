import requests
import os

api_token = os.getenv("HETZNER_DNS_KEY")
new_ip_or_cname = os.getenv("NEW_IP")
c_name = os.getenv("HETZNER_C_NAME")
record_name = os.getenv("HETZNER_RECORD_NAME")
domain_name = os.getenv("HETZNER_DOMAIN_NAME")

if c_name and ':' in c_name: #delete port for postgress
    c_name = c_name.split(':')[0] 

print(f"New IP or CNAME: {new_ip_or_cname}")
print(f"Record Name: {record_name}")
print(f"Domain Name: {domain_name}")
print(f"Cname Name: {c_name}")
print(f"API Key (first 3 chars): {api_token[:3]}...")

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


def get_record_id(zone_id, record_name, record_type):
    url = f"https://dns.hetzner.com/api/v1/records?zone_id={zone_id}"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        records = response.json()['records']
        for record in records:
            if record['name'] == record_name and record['type'] == record_type:
                return record['id']
    return None


zone_id = get_zone_id(domain_name)
if zone_id:
    print(f"Zone ID: {zone_id}")
    
    record_type = "CNAME" if c_name else "A"
    record_value = c_name + '.' if c_name else new_ip_or_cname
   
    record_id = get_record_id(zone_id, record_name, record_type)

    if record_id:
        print(f"Record ID: {record_id}")
       
        url = f"https://dns.hetzner.com/api/v1/records/{record_id}"
        print(f"url: https://dns.hetzner.com/api/v1/records/{record_id}")

        data = {
            "value": record_value,
            "ttl": 60,
            "type": record_type,
            "name": record_name,
            "zone_id": zone_id
        }
        print(f"Data for HTTP put: {data}")
        response = requests.put(url, headers=headers, json=data)
        if response.status_code == 200:
            print(f"Successfully updated {record_type} record {record_name} to {record_value}")
        else:
            print(f"Failed to update {record_type} record: {response.status_code}, {response.text}")
    else:
        print(f"No record ID found for {record_name} with type {record_type}.")
else:
    print(f"No zone ID found for {domain_name}.")
