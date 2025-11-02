#!/usr/bin/env bash
set -e

REGION="eu-north-1"
CLUSTER=arn:aws:ecs:eu-north-1:623980722470:cluster/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ
# change if your cluster name is different
SERVICE=arn:aws:ecs:eu-north-1:623980722470:service/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ/thesis-exp-v2-prod-fargate-api-Service-GX54ezhVooX8
# change if your service name is different

echo " Scaling Fargate service to 1 task..."
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --desired-count 1 > /dev/null

echo " Waiting for service to stabilize..."
aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo " Fargate is up. You can run k6 now."
