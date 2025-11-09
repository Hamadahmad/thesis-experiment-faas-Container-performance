 # Thesis Experiment — Performance Evaluation of AWS Lambda (FaaS) vs Fargate (Container)

This repository contains all resources used for the performance and cost
evaluation experiments of **Function-as-a-Service (AWS Lambda)** and
**container-based deployment (AWS Fargate)** for cloud-native applications.

It includes:
- Deployment definitions (Copilot & AWS CLI)
- Load-testing scripts (k6)
- Start/stop automation scripts for cost control
- Jupyter notebook for data analysis and visualization

---

##  Project Structure

```
thesis-experiment/
│
├── copilot/                     # Copilot service/env definitions
├── k6/                          # Load-testing scripts (warm.js, cold.js, mixed.js)
├── scripts/
│   ├── run_test.sh              # Unified test runner for Lambda & Fargate
│   ├── fargate-start.sh         # NEW: start/scale Fargate to 1 task
│   ├── fargate-stop.sh          # NEW: stop/scale Fargate to 0 tasks
│   ├── destroy_lambda.sh        # Cleanup Lambda deployment
│   └── (other helpers)
│
├── data/
│   ├── lambda/YYYY-MM-DD/...    # JSON results from k6 (warm/cold/mixed)
│   └── fargate/YYYY-MM-DD/...   # JSON results from k6 (warm/cold/mixed)
│
├── notebooks/
│   └── analysis.ipynb           # UPDATED: automatic file detection, charts, cost calc
│
└── README.md
```

---

##  1. Environment Requirements

| Component | Purpose | Notes |
|------------|----------|-------|
| **AWS CLI** | Deployment and scaling | `aws configure` for region = eu-north-1 |
| **AWS Copilot CLI** | Fargate setup | Creates ECS Cluster, ALB, Tasks |
| **Python 3 + Jupyter** | Data analysis | Used for visualization & cost analysis |
| **k6 (Grafana Labs)** | Load testing | Simulates warm/cold/mixed workloads |

---

##  2. Deployment Summary

### Lambda

```bash
./scripts/deploy_lambda.sh
# returns: https://<api-id>.execute-api.eu-north-1.amazonaws.com/prod/api/ping
```

### Fargate (Copilot)

```bash
copilot init
copilot env init --name prod
copilot svc deploy --name thesis-fargate --env prod
# returns: https://<alb-endpoint>.eu-north-1.elb.amazonaws.com/api/ping
```

---

##  3. Load-Testing Workflow

### Lambda Simple
```bash
LAMBDA_URL=$(cat .lambda_endpoint)
k6 run -e TARGET=$LAMBDA_URL k6/warm.js  --out json=data/k6_lambda_warm.json
k6 run -e TARGET=$LAMBDA_URL k6/mixed.js --out json=data/k6_lambda_mixed.json
k6 run -e LAMBDA=$LAMBDA_URL k6/cold.js  --out json=data/k6_lambda_cold.json
```
### Lambda Script

```bash
export LAMBDA_URL="https://<api-id>.execute-api.eu-north-1.amazonaws.com"
./scripts/run_test.sh lambda cold  "$LAMBDA_URL"
./scripts/run_test.sh lambda warm  "$LAMBDA_URL"
./scripts/run_test.sh lambda mixed "$LAMBDA_URL"
```
### Fargate Simple
```bash
FARGATE_URL="http://...elb.amazonaws.com"

k6 run -e TARGET=$FARGATE_URL k6/warm.js  --out json=data/k6_fargate_warm.json

k6 run -e TARGET=$FARGATE_URL k6/mixed.js --out json=data/k6_fargate_mixed.json
```
### Fargate Script

```bash
export FARGATE_URL="https://<alb-endpoint>.eu-north-1.elb.amazonaws.com"
./scripts/run_test.sh fargate warm  "$FARGATE_URL"
./scripts/run_test.sh fargate mixed "$FARGATE_URL"
```

k6 outputs JSON files to `data/<platform>/<date>/<timestamp>_<test>.json`.

###Optional Fargate Starting and Stoping Mixed Script execution

```bash
./scripts/fargate-start.sh
./scripts/run_test.sh fargate warm  $FARGATE_URL
./scripts/run_test.sh fargate cold  $FARGATE_URL
./scripts/run_test.sh fargate mixed $FARGATE_URL
./scripts/fargate-stop.sh

```
---

##  4. NEW — Cost-Control Scripts for Fargate

Fargate charges for CPU + memory *while the task is running*.
To avoid paying while idle, use the new scripts:

### Start before each test session

```bash
./scripts/fargate-start.sh
```

This scales your service to **1 task** and waits until it’s ready.

### Stop after tests complete

```bash
./scripts/fargate-stop.sh
```

This scales the service to **0 tasks**, stopping all compute cost.
The ALB stays up (minor fixed cost).

Both scripts use your real cluster:

```
Cluster ARN:  arn:aws:ecs:eu-north-1:623980722470:cluster/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ
Service ARN:  arn:aws:ecs:eu-north-1:623980722470:service/thesis-exp-v2-prod-Cluster-05tmvQtDeBPJ/thesis-exp-v2-prod-fargate-api-Service-GX54ezhVooX8
```

---

## 5. NEW — Jupyter Notebook for Automated Analysis

`notebooks/lamba_and_fargate_analysis.ipynb` now includes:

- **Automatic latest-file detection** (`data/<platform>/<YYYY-MM-DD>/<time>_...json`)
- **Latency summaries** (avg, p90, p95)
- **Bar charts, box plots, histograms, CDFs**
- **Radar & scatter charts for cross-comparison**
- **CloudWatch vs k6 alignment logic**
- **Cost computation formulas**

### Launch

```bash
jupyter notebook notebooks/analysis.ipynb
```

### Notebook Highlights

1. **Automatic data loading**  
   ```python
   all_dfs = load_latest_all()
   summary_df = summarize_latency(all_dfs)
   ```

2. **Charts generated**
   - p90/p95 bar charts  
   - avg latency comparison  
   - histograms for cold vs warm  
   - boxplots (log & linear)  
   - radar chart (normalized metrics)  
   - scatter (avg vs p95)  
   - cost breakdown (Lambda vs Fargate)

3. **CloudWatch vs k6 alignment**  
   Adjusts external vs internal latency metrics for fair comparison.

4. **Cost estimation**  
   - Lambda: `GB-seconds × $0.0000166667 + $0.20 per 1M requests`  
   - Fargate: `vCPU × hrs × rate + Memory × hrs × rate`  
   (Uses task/runtime info from CloudWatch.)

---

## 6. Multi-Day Experiment Flow (Recommended)

To perform tests over several days without continuous cost:

```bash
# Day 1
./scripts/fargate-start.sh
./scripts/run_test.sh fargate warm "$FARGATE_URL"
./scripts/run_test.sh lambda warm "$LAMBDA_URL"
./scripts/fargate-stop.sh

# Day 2 / Day 3
# repeat same pattern
```

Each session runs for minutes → cost ≈ $0.001 per test.

---

## 7. Data Collection from CloudWatch

### Lambda Duration Query (Logs Insights)

```sql
fields @timestamp, @message
| filter @message like /REPORT/
| parse @message "Duration: * ms" as duration_ms
| stats avg(duration_ms), pct(duration_ms, 90), pct(duration_ms, 95)
```

### Fargate ALB TargetResponseTime

```bash
aws cloudwatch get-metric-statistics   --region eu-north-1   --namespace AWS/ApplicationELB   --metric-name TargetResponseTime   --dimensions Name=LoadBalancer,Value=app/thesis-Publi-ztV5x3qxaw0r/6a3cd33c3cd5965c   --start-time 2025-11-02T18:00:00Z   --end-time   2025-11-02T22:00:00Z   --period 300   --statistics Average Maximum
```

---

## 8. Cost Estimation Formulas (for Notebook)

**Lambda**

```python
requests_cost = invocations * 0.20 / 1_000_000
gb_seconds = (duration_ms / 1000) * (memory_mb / 1024)
compute_cost = gb_seconds * 0.0000166667
lambda_cost = requests_cost + compute_cost
```

**Fargate**

```python
vCPU_hours = runtime_seconds / 3600 * vcpu
GB_hours   = runtime_seconds / 3600 * memory_gb
fargate_cost = vCPU_hours * 0.04048 + GB_hours * 0.004445
```

---

## 9. Results & Reproducibility Notes

- Lambda execution times (CloudWatch) are typically **5–20 ms**.  
- Fargate internal response (ALB) **1–7 ms**.  
- k6 observed end-to-end latencies **200–300 ms**, consistent with network + TLS overhead.  
- Fargate incurs cost while running; Lambda only per-request.  
- Scripts allow reproducible multi-day testing with minimal cost.

---

## 10. Cleanup

When all testing is complete:

```bash
# remove Fargate service & environment
copilot svc delete --name thesis-fargate --env prod
copilot env delete --name prod

# remove Lambda
./scripts/destroy_lambda.sh
```

---

## References

- [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [AWS Copilot Docs](https://aws.github.io/copilot-cli/)
- [k6 Docs](https://k6.io/docs/)

---

All experiments conducted in **eu-north-1 (Stockholm)** region.
