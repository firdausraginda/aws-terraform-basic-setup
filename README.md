# AWS Terraform Basic Setup

Modular Terraform project that provisions an AWS ETL pipeline — Airflow on EC2 orchestrating ECS Fargate tasks, with S3 storage and CloudWatch logging.

## Architecture

```
    Local Mac                        AWS (ap-southeast-1)
    ─────────              ┌──────────────────────────────────────┐
                           │                                      │
  docker build ──────────► │  ECR ──────► ECS Fargate             │
  & push to ECR            │              (dummy-etl-cluster)     │
                           │                    │                 │
                           │  EC2 (Airflow)     │                 │
                           │  ──triggers──────► │                 │
                           │                    ▼                 │
                           │                   S3                 │
                           │              (etl output)            │
                           │                                      │
                           │  CloudWatch Logs (7-day retention)   │
                           └──────────────────────────────────────┘
```

## Tech Stack

- **Terraform** (~> 5.0) — Infrastructure as Code
- **AWS ECS Fargate** — Serverless container execution
- **Apache Airflow 2.10** — Workflow orchestration (on EC2)
- **Amazon ECR** — Container image registry
- **Amazon S3** — Data storage
- **CloudWatch Logs** — Centralized logging
- **Docker** — Containerized ETL job
- **Python 3.11** — ETL script runtime

## Project Structure

```
.
├── main.tf                 # Root module wiring
├── versions.tf             # Provider config (AWS, ap-southeast-1)
├── outputs.tf              # Root outputs
│
├── vpc/                    # VPC (172.31.0.0/16)
├── subnet/                 # Subnet (172.31.16.0/20, public)
├── sg/                     # Security groups (SSH + Airflow UI)
├── ec2/                    # EC2 instance (t3.small, Airflow host)
├── ecr/                    # ECR repository (dummy-etl)
├── ecs/                    # ECS cluster, task definition, SG
├── iam/                    # IAM roles for ECS + EC2
├── s3/                     # S3 bucket for ETL output
│
├── airflow/                # Airflow Dockerfile, DAG, docker-compose
│   └── dags/
│       └── ecs_etl_dag.py
├── docker/                 # ETL container image + build script
│
├── INFRASTRUCTURE.md       # Detailed infrastructure reference
└── SETUP_GUIDE.md          # Step-by-step setup walkthrough
```

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- Docker installed

### Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### Build & Push ETL Image

```bash
./docker/build_and_push.sh
```

### Deploy Airflow

Copy the `airflow/` directory to the EC2 instance and run:

```bash
docker compose up -d
```

Access Airflow UI at `http://<EC2_PUBLIC_IP>:8080`

## Documentation

- **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)** — Full module-by-module breakdown of all resources, configurations, variables, outputs, and dependency graph
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** — Step-by-step guide for installing tools, importing existing AWS resources with Terraformer, and organizing modules

## How It Works

1. **Terraform** provisions all AWS infrastructure (VPC, subnet, EC2, ECS, ECR, S3, IAM, security groups)
2. **ETL container image** is built locally and pushed to ECR
3. **Airflow** runs on EC2 and triggers ECS Fargate tasks via `EcsRunTaskOperator`
4. **ECS Fargate** pulls the image from ECR, runs the ETL job, and writes results to S3
5. **CloudWatch Logs** captures container output, streamed back to the Airflow UI
