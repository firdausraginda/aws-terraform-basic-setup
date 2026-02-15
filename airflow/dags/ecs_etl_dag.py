from airflow import DAG
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from datetime import datetime, timedelta

with DAG(
    dag_id="ecs_dummy_etl",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
) as dag:

    run_etl = EcsRunTaskOperator(
        task_id="run_dummy_etl",
        region_name="ap-southeast-1",
        cluster="dummy-etl-cluster",
        task_definition="dummy-etl-task",
        launch_type="FARGATE",
        network_configuration={
            "awsvpcConfiguration": {
                "subnets": ["subnet-0e59d3063249f2a7c"],
                "securityGroups": ["sg-0249ae52f65168b5d"],
                "assignPublicIp": "ENABLED",
            }
        },
        overrides={},
        awslogs_group="/ecs/dummy-etl",
        awslogs_stream_prefix="etl",
        awslogs_region="ap-southeast-1",
        awslogs_fetch_interval=timedelta(seconds=5),
        number_logs_exception=10,
    )
