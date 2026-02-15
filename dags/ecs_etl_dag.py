from airflow import DAG
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from datetime import datetime

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
