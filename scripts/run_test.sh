
#!/bin/bash
# Usage: ./scripts/run_test.sh fargate warm $FARGATE_URL
#        ./scripts/run_test.sh lambda cold $LAMBDA_URL

PLATFORM=$1   # fargate or lambda
SCENARIO=$2   # warm / mixed / cold / spike
URL=$3        # full base URL (without /api/ping at the end)

DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H-%M-%S")

# Create nested folder: data/fargate/<date>/  or data/lambda/<date>/
mkdir -p data/${PLATFORM}/${DATE}

# Run k6 test and write timestamped JSON result inside the correct folder
OUTFILE=data/${PLATFORM}/${DATE}/${TIME}_${PLATFORM}_${SCENARIO}.json

echo "  Starting ${PLATFORM} ${SCENARIO} test at $(date)"
#We will only pass URL k6 scripts already got api/ping
k6 run -e TARGET=${URL} k6/${SCENARIO}.js --out json=${OUTFILE}
echo "  Finished. Results saved to ${OUTFILE}"
