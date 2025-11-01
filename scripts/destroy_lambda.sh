
#!/usr/bin/env bash
set -euo pipefail

FUNC_NAME="thesis-faas-py"
ROLE_NAME="lambda-basic-role"
API_NAME="thesis-http"

echo "==> Deleting API Gateway HTTP API"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='${API_NAME}'].ApiId" --output text || true)
if [ -n "${API_ID:-}" ]; then
  aws apigatewayv2 delete-api --api-id "$API_ID" || true
fi

echo "==> Deleting Lambda function"
aws lambda delete-function --function-name "$FUNC_NAME" || true

echo "==> Detaching and deleting IAM role"
aws iam detach-role-policy --role-name "$ROLE_NAME"   --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true
aws iam delete-role --role-name "$ROLE_NAME" || true

rm -f .lambda_endpoint lambda.zip
echo "Cleanup complete."
