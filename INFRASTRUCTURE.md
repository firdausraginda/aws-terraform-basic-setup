# Infrastructure Summary

## Overview

This project provisions an AWS-based ETL pipeline using Terraform. Airflow runs on an EC2 instance and orchestrates ECS Fargate tasks that execute a containerized ETL job. Results are written to S3.

```
                        ┌────────────────────────────────────────────────┐
                        │                 AWS (ap-southeast-1)           │
                        │                                                │
                        │  ┌──────────┐       ┌──────────────────────┐   │
                        │  │   ECR    │       │      ECS Fargate     │   │
    Local Mac           │  │ dummy-etl├──────►│  dummy-etl-cluster   │   │
    ─────────           │  └──────────┘       │  ┌────────────────┐  │   │
  docker build ────────►│                     │  │  etl container │  │   │
  & push to ECR         │                     │  └───────┬────────┘  │   │
                        │  ┌──────────────┐   │          │           │   │
                        │  │   EC2 (t3s)  │   └──────────┼───────────┘   │
                        │  │   Airflow    ├──triggers──► │               │
                        │  │   :8080      │              │               │
                        │  └──────────────┘              ▼               │
                        │                          ┌──────────┐          │
                        │                          │    S3    │          │
                        │                          │ dummy-etl│          │
                        │                          └──────────┘          │
                        │                                                │
                        │  ┌─────────────────────────────┐               │
                        │  │  CloudWatch Logs            │               │
                        │  │  /ecs/dummy-etl (7d retain) │               │
                        │  └─────────────────────────────┘               │
                        └────────────────────────────────────────────────┘
```

**Region:** `ap-southeast-1` (Singapore)
**Provider:** `hashicorp/aws ~> 5.0`

---

## Module Breakdown

### 1. VPC (`vpc/`)

**Resources:**

| Resource | Name | Config |
|----------|------|--------|
| `aws_vpc.default` | — | CIDR `172.31.0.0/16`, DNS hostnames + DNS support enabled, default tenancy |

**Variables:** None
**Outputs:**

| Output | Value |
|--------|-------|
| `default_vpc_id` | VPC ID |

---

### 2. Subnet (`subnet/`)

**Resources:**

| Resource | Name | Config |
|----------|------|--------|
| `aws_subnet.default_ap_southeast_1c` | — | CIDR `172.31.16.0/20`, public IPs on launch |

**Variables:**

| Variable | Type | Source |
|----------|------|--------|
| `default_vpc_id` | `string` | `module.vpc.default_vpc_id` |

**Outputs:**

| Output | Value |
|--------|-------|
| `default_ap_southeast_1c_id` | Subnet ID |

---

### 3. Security Groups (`sg/`)

**Resources:**

| Resource | Name | Ingress | Egress |
|----------|------|---------|--------|
| `aws_security_group.default_vpc_default` | `default` | All traffic (self-referencing) | All traffic to `0.0.0.0/0` |
| `aws_security_group.launch_wizard_1` | `launch-wizard-1` | TCP 22 (SSH) from `0.0.0.0/0`, TCP 8080 (Airflow UI) from `0.0.0.0/0` | All traffic to `0.0.0.0/0` |

**Variables:**

| Variable | Type | Source |
|----------|------|--------|
| `default_vpc_id` | `string` | `module.vpc.default_vpc_id` |

**Outputs:**

| Output | Value |
|--------|-------|
| `default_vpc_default_id` | Default SG ID |
| `launch_wizard_1_id` | Launch wizard SG ID |

---

### 4. EC2 (`ec2/`)

**Resources:**

| Resource | Name Tag | Config |
|----------|----------|--------|
| `aws_instance.airflow_test` | `airflow-test-ec2` | See details below |

**EC2 Instance Details:**

| Setting | Value |
|---------|-------|
| AMI | `ami-08d59269edddde222` |
| Instance type | `t3.small` |
| AZ | `ap-southeast-1b` |
| Public IP | Yes |
| CPU | 1 core, 2 threads (unlimited credits) |
| EBS optimized | Yes |
| Root volume | 30 GB gp3, 3000 IOPS, 125 MB/s throughput |
| IMDSv2 | Required (`http_tokens = required`) |
| IAM profile | `airflow-ec2-profile` (from IAM module) |

**Variables:**

| Variable | Type | Source |
|----------|------|--------|
| `iam_instance_profile` | `string` | `module.iam.airflow_ec2_instance_profile_name` |

**Outputs:**

| Output | Value |
|--------|-------|
| `airflow_test_instance_id` | Instance ID |

---

### 5. ECR (`ecr/`)

**Resources:**

| Resource | Name | Config |
|----------|------|--------|
| `aws_ecr_repository.etl` | `dummy-etl` | Mutable tags, force delete enabled, scan on push disabled |

**Variables:** None
**Outputs:**

| Output | Value |
|--------|-------|
| `repository_url` | ECR repository URL |
| `repository_arn` | ECR repository ARN |

---

### 6. S3 (`s3/`)

**Resources:**

| Resource | Name | Config |
|----------|------|--------|
| `aws_s3_bucket.etl` | `dummy-etl-pipeline-<ACCOUNT_ID>` | Force destroy enabled |

Uses `data.aws_caller_identity.current` to dynamically include the AWS account ID in the bucket name.

**Variables:** None
**Outputs:**

| Output | Value |
|--------|-------|
| `bucket_name` | Bucket name |
| `bucket_arn` | Bucket ARN |

---

### 7. IAM (`iam/`)

**Roles and Policies:**

| Role | Trust Principal | Policies |
|------|----------------|----------|
| `ecs-task-execution-role` | `ecs-tasks.amazonaws.com` | `AmazonECSTaskExecutionRolePolicy` (AWS managed) |
| `ecs-task-role` | `ecs-tasks.amazonaws.com` | Inline: S3 `GetObject`, `PutObject`, `ListBucket` on ETL bucket |
| `airflow-ec2-role` | `ec2.amazonaws.com` | Inline: S3 access (same as above) + ECS `RunTask`/`DescribeTasks`/`StopTask` + `iam:PassRole` for ECS roles + CloudWatch Logs read |

**Instance Profile:** `airflow-ec2-profile` (wraps `airflow-ec2-role`)

**Variables:**

| Variable | Type | Source |
|----------|------|--------|
| `s3_bucket_arn` | `string` | `module.s3.bucket_arn` |

**Outputs:**

| Output | Value |
|--------|-------|
| `ecs_task_execution_role_arn` | Execution role ARN |
| `ecs_task_role_arn` | Task role ARN |
| `airflow_ec2_instance_profile_name` | EC2 instance profile name |

---

### 8. ECS (`ecs/`)

**Resources:**

| Resource | Name | Config |
|----------|------|--------|
| `aws_ecs_cluster.main` | `dummy-etl-cluster` | — |
| `aws_cloudwatch_log_group.ecs` | `/ecs/dummy-etl` | 7-day retention |
| `aws_security_group.ecs_task` | `ecs-task-sg` | Egress-only: all traffic to `0.0.0.0/0` |
| `aws_ecs_task_definition.etl` | `dummy-etl-task` | See details below |

**Task Definition Details:**

| Setting | Value |
|---------|-------|
| Network mode | `awsvpc` |
| Launch type | `FARGATE` |
| CPU | 256 (0.25 vCPU) |
| Memory | 512 MB |
| Container name | `etl` |
| Image | `<ECR_URL>:latest` |
| Env var | `S3_BUCKET` = bucket name |
| Log driver | `awslogs` (group: `/ecs/dummy-etl`, prefix: `etl`) |

**Variables:**

| Variable | Type | Source |
|----------|------|--------|
| `ecr_repository_url` | `string` | `module.ecr.repository_url` |
| `ecs_task_execution_role_arn` | `string` | `module.iam.ecs_task_execution_role_arn` |
| `ecs_task_role_arn` | `string` | `module.iam.ecs_task_role_arn` |
| `subnet_id` | `string` | `module.subnet.default_ap_southeast_1c_id` |
| `vpc_id` | `string` | `module.vpc.default_vpc_id` |
| `s3_bucket_name` | `string` | `module.s3.bucket_name` |

**Outputs:**

| Output | Value |
|--------|-------|
| `cluster_name` | Cluster name |
| `task_definition_arn` | Task definition ARN |
| `task_security_group_id` | ECS task SG ID |
| `subnet_id` | Subnet ID (pass-through) |

---

## Module Dependency Graph

```
vpc ──────────┬──► subnet ──────────► ecs
              │                        ▲
              ├──► sg                  │
              │                        │
              └────────────────────────┤
                                       │
s3 ──► iam ────────────────────────────┤
                │                      │
                ▼                      │
               ec2                     │
                                       │
ecr ───────────────────────────────────┘
```

**Dependency details:**

| Module | Depends On | Via |
|--------|-----------|-----|
| `subnet` | `vpc` | `default_vpc_id` |
| `sg` | `vpc` | `default_vpc_id` |
| `ec2` | `iam` | `airflow_ec2_instance_profile_name` |
| `iam` | `s3` | `bucket_arn` |
| `ecs` | `vpc`, `subnet`, `ecr`, `iam`, `s3` | `vpc_id`, `subnet_id`, `repository_url`, role ARNs, `bucket_name` |

---

## Root Outputs

| Output | Source |
|--------|--------|
| `ecr_repository_url` | `module.ecr.repository_url` |
| `ecs_cluster_name` | `module.ecs.cluster_name` |
| `ecs_task_security_group_id` | `module.ecs.task_security_group_id` |
| `ecs_subnet_id` | `module.ecs.subnet_id` |
| `s3_bucket_name` | `module.s3.bucket_name` |

---

## Airflow & Docker Setup

These components are **not managed by Terraform** and are deployed manually.

### ETL Container (`docker/`)

| File | Purpose |
|------|---------|
| `Dockerfile` | `python:3.11-slim` base, installs `boto3`, runs `etl.py` |
| `etl.py` | Dummy ETL: simulates extract/transform/load, writes a timestamped result file to S3 |
| `build_and_push.sh` | Builds image with `--platform linux/amd64`, tags and pushes to ECR |

**Build command:** `./docker/build_and_push.sh [tag]` (defaults to `latest`)

### Airflow (`airflow/`)

| File | Purpose |
|------|---------|
| `Dockerfile` | `apache/airflow:slim-2.10.4-python3.11` + `apache-airflow-providers-amazon` |
| `docker-compose.yml` | Single-container Airflow with `SequentialExecutor`, SQLite DB, port 8080 |
| `dags/ecs_etl_dag.py` | DAG `ecs_dummy_etl`: triggers ECS Fargate task via `EcsRunTaskOperator` |

**Airflow DAG config:**

| Setting | Value |
|---------|-------|
| DAG ID | `ecs_dummy_etl` |
| Schedule | Manual (None) |
| Cluster | `dummy-etl-cluster` |
| Task definition | `dummy-etl-task` |
| Launch type | `FARGATE` |
| Public IP | Enabled |
| Log streaming | `awslogs_fetch_interval=5s`, `number_logs_exception=10` |

**Deployment:** Files are manually copied to the EC2 instance and launched with `docker compose up -d`.

---

## Key Values Reference

| Resource | Key | Value |
|----------|-----|-------|
| VPC | CIDR | `172.31.0.0/16` |
| Subnet | CIDR | `172.31.16.0/20` |
| EC2 | Instance type | `t3.small` |
| EC2 | Volume | 30 GB gp3 |
| EC2 | AMI | `ami-08d59269edddde222` |
| ECS | CPU / Memory | 256 (0.25 vCPU) / 512 MB |
| ECS | Cluster | `dummy-etl-cluster` |
| ECS | Task family | `dummy-etl-task` |
| ECR | Repository | `dummy-etl` |
| S3 | Bucket | `dummy-etl-pipeline-<ACCOUNT_ID>` |
| CloudWatch | Log group | `/ecs/dummy-etl` (7-day retention) |
| Security Group | SSH | Port 22 from `0.0.0.0/0` |
| Security Group | Airflow UI | Port 8080 from `0.0.0.0/0` |
| Region | — | `ap-southeast-1` |
