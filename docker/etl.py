import os
import time

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

    print("=" * 40)
    print("ETL job completed successfully!")
    print("=" * 40)

if __name__ == "__main__":
    main()
