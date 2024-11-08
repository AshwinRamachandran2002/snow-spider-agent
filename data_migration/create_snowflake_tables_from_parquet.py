import snowflake.connector
import json
import argparse
import os
import threading
from google.cloud import storage
from concurrent.futures import ThreadPoolExecutor


# Apply transformations to the name
def transform_name(name):
    # Remove quotes and replace '-' with '_'
    name = name.replace("-", "_").replace('"', "")

    # Add underscore prefix if name starts with a number
    if name[0].isdigit():
        name = f"_{name}"

    if name.startswith("DATA_") and name[5].isdigit():  # DATA_123 -> _123
        name = name[4:]

    return name.upper()


def quote_name(name):
    """Quote names."""
    return f'"{name}"'


def load_progress(log_file):
    """Load the progress log to determine which tables have already been processed."""
    if not os.path.exists(log_file):
        return set()
    with open(log_file, "r") as f:
        completed_tables = set(line.strip() for line in f)
    return completed_tables


def update_progress(log_file, db_name, schema, table_name, lock):
    """Update the progress log with a newly completed Snowflake table."""
    with lock:
        with open(log_file, "a") as f:
            f.write(f"{db_name}.{schema}.{table_name}\n")


def list_gcs_files(bucket_name, project_id, dataset_name):
    """List Parquet files in a GCS bucket for a specific dataset."""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    prefix = f"{project_id}/{dataset_name}/"

    # List all the objects in the GCS path
    blobs = bucket.list_blobs(prefix=prefix)

    # Extract unique table names from the file names
    table_names = set()
    for blob in blobs:
        filename = blob.name.split("/")[-1]
        if filename.endswith(".parquet"):
            table_name = filename.split("-")[
                0
            ]  # Extract table_name from {table_name}-*.parquet
            table_names.add(table_name)

    return table_names


def process_dataset(data, args, completed_tables, lock):
    """Process a single dataset."""

    dataset_ids = data["id"]  # List of BigQuery datasets
    db_name = data["db_name"]  # Snowflake database name

    bucket_uri = args.bucket.rstrip("/")
    bucket_name = bucket_uri.replace("gs://", "")

    # Each thread creates its own Snowflake connection and cursor
    conn = snowflake.connector.connect(
        account=args.snowflake_account,
        user=args.snowflake_user,
        password=args.snowflake_password,
        warehouse=args.snowflake_warehouse,
        role=args.snowflake_role,
    )
    cur = conn.cursor()

    # Create or replace a storage integration for GCS with the provided credentials
    storage_integration_name = "gcs_data_integration"

    # Ensure that Snowflake database (schema) exists
    cur.execute(f"CREATE DATABASE IF NOT EXISTS {quote_name(db_name)}")
    cur.execute(
        f"USE DATABASE {quote_name(db_name)}"
    )  # Ensure database is selected for future operations

    # Create a Parquet file format in Snowflake (must be tied to the current database)
    file_format_name = "my_parquet_format"
    cur.execute(
        f"""
        CREATE OR REPLACE FILE FORMAT {file_format_name}
        TYPE = PARQUET
        REPLACE_INVALID_CHARACTERS=TRUE
        BINARY_AS_TEXT=FALSE;
    """
    )

    for dataset_id in dataset_ids:
        project_id, dataset_name = dataset_id.split(".")

        # List all table names based on Parquet files in GCS for this dataset
        table_names = list_gcs_files(bucket_name, project_id, dataset_name)

        for table_name in table_names:
            # Check if table has already been processed
            table_name = table_name.strip()
            if f"{db_name}.{dataset_name}.{table_name}" in completed_tables:
                continue

            # Create schema if it doesn't exist
            cur.execute(f"CREATE SCHEMA IF NOT EXISTS {transform_name(dataset_name)}")
            cur.execute(f"USE SCHEMA {transform_name(dataset_name)}")

            # GCS path to Parquet file (relative to the stage)
            parquet_file_path = f"{table_name}-*.parquet"
            example_parquet_file_path = f"{table_name}-000000000000.parquet"

            # Create the stage for loading data from GCS using the storage integration
            stage_name = f"{transform_name(dataset_name)}_stage"
            # If it starts with a number, prepend with an underscore
            if stage_name[0].isdigit():
                stage_name = "_" + stage_name

            cur.execute(
                f"""
                CREATE OR REPLACE STAGE {stage_name}
                URL = 'gcs://{bucket_name}/{project_id}/{dataset_name}/'
                STORAGE_INTEGRATION = {storage_integration_name}
                FILE_FORMAT = (TYPE = PARQUET)
            """
            )

            # Step 1: Infer schema from Parquet files using the INFER_SCHEMA function
            cur.execute(
                f"""
                SELECT COLUMN_NAME, TYPE FROM TABLE(INFER_SCHEMA(
                    LOCATION=>'@{stage_name}/{example_parquet_file_path}',
                    FILE_FORMAT=>'{file_format_name}')
                );
            """
            )  # only the first file is used for schema inference
            schema_inference = cur.fetchall()

            # Step 2: Create a new table with the inferred schema, always quoting column names
            columns_definition = ", ".join(
                [f"{quote_name(col[0])} {col[1]}" for col in schema_inference]
            )
            # Write failed table creation to a log file
            try:
                cur.execute(
                    f"""
                    CREATE OR REPLACE TABLE {transform_name(table_name)} ({columns_definition});
                """
                )
            except Exception as e:
                with open("failed_tables.log", "a") as f:
                    f.write(
                        f"Error creating table {table_name} in {dataset_name}: {e}\n"
                    )
                continue

            # Build the SELECT statement with explicit casts, quoting column names
            select_columns = ", ".join(
                [f"$1:{quote_name(col[0])}::{col[1]}" for col in schema_inference]
            )

            # Define the pattern to match the Parquet files for the specific table
            pattern = f"^{table_name}-.*\\.parquet$"  # Regular expression pattern

            # Step 3: Load the Parquet data into the table using COPY INTO with explicit casts and pattern
            # If it fails, log the error and continue to the next table
            try:
                cur.execute(
                    f"""
                    COPY INTO {transform_name(table_name)}
                    FROM (
                        SELECT {select_columns}
                        FROM '@{stage_name}'
                        (FILE_FORMAT => '{file_format_name}', PATTERN => '{pattern}')
                    )
                    ON_ERROR = {'CONTINUE' if args.error_tolerate else 'ABORT_STATEMENT'}
                """
                )
            except Exception as e:
                with open("failed_loads.log", "a") as f:
                    f.write(
                        f"Error loading table {table_name} in {dataset_name}: {e}\n"
                    )
                continue

            print(f"Loaded {dataset_id} into {db_name}.{dataset_name}.{table_name}")

            # Update the progress log
            update_progress(args.progress_log, db_name, dataset_name, table_name, lock)

    cur.close()
    conn.close()


def main():
    parser = argparse.ArgumentParser(
        description="Load exported Parquet files from GCS into Snowflake with inferred schema."
    )
    parser.add_argument(
        "--bucket", help="GCS bucket URI (e.g., gs://my-us-bucket)", required=True
    )
    parser.add_argument(
        "--jsonl-file",
        help="Path to JSONL file containing dataset mappings",
        default="./migration_map.jsonl",
    )
    parser.add_argument(
        "--snowflake-account", help="Snowflake account identifier", required=True
    )
    parser.add_argument("--snowflake-user", help="Snowflake username", required=True)
    parser.add_argument(
        "--snowflake-password", help="Snowflake password", required=True
    )
    parser.add_argument(
        "--snowflake-warehouse", help="Snowflake warehouse name", required=True
    )
    parser.add_argument("--snowflake-role", help="Snowflake role", default="SYSADMIN")
    parser.add_argument(
        "--progress-log", help="File to log completed tables", default="progress.log"
    )
    parser.add_argument(
        "--error-tolerate",
        help="Whether to tolerate errors during table loading. If set to True, problematic rows will be skipped.",
        action="store_true",
    )
    parser.add_argument(
        "--max-workers", help="Maximum number of worker threads", type=int, default=4
    )

    args = parser.parse_args()

    # Load progress log
    progress_lock = threading.Lock()
    completed_tables = load_progress(args.progress_log)

    # Read the JSONL file and collect dataset entries
    datasets = []
    with open(args.jsonl_file, "r") as f:
        for line in f:
            data = json.loads(line)
            datasets.append(data)

    # Use ThreadPoolExecutor for multithreading
    with ThreadPoolExecutor(max_workers=args.max_workers) as executor:
        futures = []
        for data in datasets:
            future = executor.submit(
                process_dataset, data, args, completed_tables, progress_lock
            )
            futures.append(future)

        # Wait for all threads to complete
        for future in futures:
            try:
                future.result()
            except Exception as e:
                print(f"Error processing dataset: {e}")


if __name__ == "__main__":
    main()
