from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from datetime import datetime


S3_BUCKET = "dummy-etl-pipeline-042655076445"
S3_KEY = "output/etl_result.txt"


def write_to_s3(**context):
    run_id = context["run_id"]
    ts = context["ts"]
    content = f"ETL pipeline completed successfully!\nRun ID: {run_id}\nTimestamp: {ts}\n"

    hook = S3Hook(aws_conn_id="aws_default")
    hook.load_string(
        string_data=content,
        key=S3_KEY,
        bucket_name=S3_BUCKET,
        replace=True,
    )
    print(f"Wrote result to s3://{S3_BUCKET}/{S3_KEY}")


with DAG(
    dag_id="ecs_dummy_etl",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
) as dag:

    run_etl = EcsRunTaskOperator(
        task_id="run_dummy_etl",
        cluster="dummy-etl-cluster",
        task_definition="dummy-etl-task",
        launch_type="FARGATE",
        network_configuration={
            "awsvpcConfiguration": {
                "subnets": ["subnet-0e59d3063249f2a7c"],
                "securityGroups": [],  # fill after terraform apply
                "assignPublicIp": "ENABLED",
            }
        },
        overrides={},
        awslogs_group="/ecs/dummy-etl",
        awslogs_stream_prefix="etl",
        awslogs_region="ap-southeast-1",
    )

    dump_to_s3 = PythonOperator(
        task_id="dump_result_to_s3",
        python_callable=write_to_s3,
    )

    run_etl >> dump_to_s3
