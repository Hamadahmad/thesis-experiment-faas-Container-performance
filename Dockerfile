
FROM python:3.12-slim
WORKDIR /app
COPY app/handler.py app/server.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
ENV SERVICE_NAME=fargate
EXPOSE 8080
CMD ["python","server.py"]
