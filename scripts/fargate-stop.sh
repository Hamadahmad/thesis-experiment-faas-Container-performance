#!/usr/bin/env bash
set -e

REGION="eu-north-1"
CLUSTER=arn:aws:ecs:eu-north-1:623980722470:cluster/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ
SERVICE=arn:aws:ecs:eu-north-1:623980722470:service/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ/thesis-exp-v2-prod-fargate-api-Service-GX54ezhVooX8

echo " Scaling Fargate service to 0..."
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --desired-count 0 > /dev/null

echo " Waiting for tasks to stop..."
aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo " Fargate stopped. Cost is basically 0 now (LB may stay)."
