
#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-$(aws configure get region)}"
: "${REGION:?Set AWS_REGION or configure a default region}"

FUNC_NAME="thesis-faas-py"
ROLE_NAME="lambda-basic-role"

echo "==> Packaging Lambda"
rm -f lambda.zip
mkdir -p lambda_pkg
cp app/handler.py lambda_pkg/
pushd lambda_pkg >/dev/null
zip -r9 ../lambda.zip . >/dev/null
popd >/dev/null

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "==> Creating IAM role"
  aws iam create-role --role-name "$ROLE_NAME"     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
  aws iam attach-role-policy --role-name "$ROLE_NAME"     --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole >/dev/null
  echo "Waiting 10s for role propagation..."
  sleep 10
fi

if ! aws lambda get-function --function-name "$FUNC_NAME" >/dev/null 2>&1; then
  echo "==> Creating Lambda function"
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
  aws lambda create-function     --function-name "$FUNC_NAME"     --runtime python3.12     --zip-file fileb://lambda.zip     --handler handler.lambda_handler     --role "$ROLE_ARN"     --memory-size 256     --timeout 10     --environment Variables="{SERVICE_NAME=lambda}" >/dev/null
else
  echo "==> Updating Lambda code"
  aws lambda update-function-code     --function-name "$FUNC_NAME"     --zip-file fileb://lambda.zip >/dev/null
fi

echo "==> Creating/Updating HTTP API and integration"
API_NAME="thesis-http"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='${API_NAME}'].ApiId" --output text || true)
if [ -z "${API_ID}" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNC_NAME}"
  API_ID=$(aws apigatewayv2 create-api --name "$API_NAME" --protocol-type HTTP --target "$LAMBDA_ARN" --query ApiId --output text)
  aws lambda add-permission     --function-name "${FUNC_NAME}"     --statement-id apigw$(date +%s)     --action lambda:InvokeFunction     --principal apigateway.amazonaws.com     --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/*" >/dev/null
fi

API_ENDPOINT=$(aws apigatewayv2 get-api --api-id "$API_ID" --query "ApiEndpoint" --output text)
echo "$API_ENDPOINT" > .lambda_endpoint
echo "==> Lambda endpoint: $API_ENDPOINT"
echo "Test: curl ${API_ENDPOINT}/api/ping"
