
from flask import Flask, jsonify
from handler import do_work

app = Flask(__name__)

@app.get("/api/ping")
def ping():
    return jsonify(do_work())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
