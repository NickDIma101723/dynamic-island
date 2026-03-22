import requests

api_key = "AIzaSyC0gOEcq_4UeWKPYPLRMNnvtXkVZREOt1g"
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"

prompt = "Hello!"
body = {"contents": [{"parts": [{"text": prompt}]}]}

response = requests.post(url, json=body, headers={"Content-Type": "application/json"})
print("Status Code:", response.status_code)
print("Response:", response.text)
