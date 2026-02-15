import os
import time
from datetime import datetime, timezone

import boto3


def main():
    bucket = os.environ.get("S3_BUCKET", "not set")

    print("=" * 40)
    print("ETL job starting...")
    print(f"S3 Bucket: {bucket}")
    print("=" * 40)

    print("Step 1: Extracting data...")
    time.sleep(2)

    print("Step 2: Transforming data...")
    time.sleep(2)

    print("Step 3: Loading data...")
    time.sleep(1)

    print("Step 4: Writing result to S3...")
    timestamp = datetime.now(timezone.utc).isoformat()
    content = f"ETL pipeline completed successfully!\nTimestamp: {timestamp}\n"

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=bucket,
        Key=f"output/etl_result_{timestamp}.txt",
        Body=content,
    )
    print(f"Wrote result to s3://{bucket}/output/etl_result_{timestamp}.txt")

    print("=" * 40)
    print("ETL job completed successfully!")
    print("=" * 40)


if __name__ == "__main__":
    main()
