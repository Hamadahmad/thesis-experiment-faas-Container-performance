
# Thesis Experiment Starter

Compare **AWS Lambda** (Python) and **AWS Fargate** (Docker) using k6.
See the step-by-step in the chat; quick commands are repeated below.

## Quick start
1) Prereqs: AWS CLI v2, Docker, Node.js, k6, Python 3.12+.
2) Configure AWS: `aws configure` (choose a close region, e.g. eu-north-1).
3) Deploy Lambda: `./scripts/deploy_lambda.sh`
4) Get endpoint: `cat .lambda_endpoint` then:
```bash
LAMBDA_URL=$(cat .lambda_endpoint)
k6 run -e TARGET=$LAMBDA_URL k6/warm.js  --out json=data/k6_lambda_warm.json
k6 run -e TARGET=$LAMBDA_URL k6/mixed.js --out json=data/k6_lambda_mixed.json
k6 run -e LAMBDA=$LAMBDA_URL k6/cold.js  --out json=data/k6_lambda_cold.json
```
5) Fargate via Copilot (install Copilot first):
```bash
copilot init --app thesis-exp --name fargate-api --type "Load Balanced Web Service"   --dockerfile ./Dockerfile --port 8080
copilot env init --name prod --region eu-north-1
copilot svc deploy --name fargate-api --env prod
```
Then use the printed Service URL:
```bash
FARGATE_URL="http://...elb.amazonaws.com"
k6 run -e TARGET=$FARGATE_URL k6/warm.js  --out json=data/k6_fargate_warm.json
k6 run -e TARGET=$FARGATE_URL k6/mixed.js --out json=data/k6_fargate_mixed.json
```
6) Export CloudWatch REPORT metrics and Cost Explorer CSVs for run windows into `data/`.
7) Cleanup:
```bash
./scripts/destroy_lambda.sh
copilot svc delete --name fargate-api --env prod
copilot app delete
```
