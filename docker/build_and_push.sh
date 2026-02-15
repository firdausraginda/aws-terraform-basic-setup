#!/bin/bash
set -e

REGION="ap-southeast-1"
ACCOUNT_ID="042655076445"
REPO_NAME="dummy-etl"
IMAGE_TAG="${1:-latest}"

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
FULL_IMAGE="${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}"

echo "==> Logging in to ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

echo "==> Building image..."
docker build --platform linux/amd64 -t "$REPO_NAME" "$(dirname "$0")"

echo "==> Tagging as ${FULL_IMAGE}..."
docker tag "$REPO_NAME:latest" "$FULL_IMAGE"

echo "==> Pushing to ECR..."
docker push "$FULL_IMAGE"

echo "==> Done! Image pushed: ${FULL_IMAGE}"
