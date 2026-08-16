import base64
import json
import requests

IMAGE_PATH = "fridge.jpg"

with open(IMAGE_PATH, "rb") as image_file:
    image_base64 = base64.b64encode(
        image_file.read()
    ).decode("utf-8")

payload = {
    "image": f"data:image/jpeg;base64,{image_base64}"
}

response = requests.post(
    "http://127.0.0.1:8787",
    json=payload
)

print("Status:", response.status_code)
print(json.dumps(response.json(), indent=2))