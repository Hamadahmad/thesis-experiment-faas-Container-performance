
import json, time, os, random

def do_work():
    time.sleep(random.uniform(0.003, 0.007))
    return {"ok": True, "service": os.environ.get("SERVICE_NAME","unknown")}

def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type":"application/json"},
        "body": json.dumps(do_work())
    }
