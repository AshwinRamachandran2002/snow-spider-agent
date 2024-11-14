import argparse

from google.cloud import bigquery
from google.cloud import storage
from tqdm.auto import tqdm


def main():
    parser = argparse.ArgumentParser(
        description="Export BigQuery tables and views to GCS as Parquet files with sampling."
    )
    parser.add_argument("--project", help="GCP project ID", default=None)
    parser.add_argument(
        "--bucket", help="GCS bucket URI (e.g., gs://my-us-bucket)", required=True
    )
    parser.add_argument(
        "--eu-bucket",
        help="GCS bucket URI for EU datasets (e.g., gs://my-eu-bucket)",
        required=False,
    )
    parser.add_argument(
        "--input-file",
        help="Path to a text file containing project.dataset_id",
        default=None,
    )
    parser.add_argument(
        "--sample-ratio",
        type=float,
        help="Sampling ratio (e.g., 0.01 for 1%)",
        default=1.0,
    )

    args = parser.parse_args()

    if args.sample_ratio > 1.0:
        raise ValueError(
            "Upsamling is not supported. Sampling ratio must be between 0 and 1."
        )

    client = bigquery.Client(project=args.project)
    storage_client = storage.Client()
    project = client.project
    bucket_uri = args.bucket.rstrip("/")
    eu_bucket_uri = args.eu_bucket.rstrip("/") if args.eu_bucket else None

    bucket_name = bucket_uri.replace("gs://", "")

    # Load datasets from file if --input-file is provided
    if args.input_file:
        with open(args.input_file, "r") as f:
            dataset_list = [line.strip() for line in f if line.strip()]
    else:
        # If no file provided, list datasets from the BigQuery project
        datasets = list(client.list_datasets())
        if not datasets:
            print(f"{project} project does not contain any datasets.")
            return
        dataset_list = [f"{project}.{dataset.dataset_id}" for dataset in datasets]

    for dataset_identifier in tqdm(dataset_list):
        project_id, dataset_id = dataset_identifier.split(".")
        dataset_ref = client.dataset(dataset_id, project=project_id)

        # Get dataset location
        dataset = client.get_dataset(dataset_ref)
        dataset_location = dataset.location

        # Choose the appropriate bucket based on dataset location
        if dataset_location.upper() == "EU" and eu_bucket_uri:
            bucket = storage_client.bucket(eu_bucket_uri.replace("gs://", ""))
            chosen_bucket_uri = eu_bucket_uri
        else:
            bucket = storage_client.bucket(bucket_name)
            chosen_bucket_uri = bucket_uri

        tables = list(client.list_tables(dataset_ref))

        if not tables:
            print(f"Dataset {dataset_id} does not contain any tables.")
            continue

        for table in tables:
            table_id = table.table_id
            table_ref = dataset_ref.table(table_id)

            # Check if the table is a view
            table = client.get_table(table_ref)
            if table.table_type == "VIEW":
                print(f"Materializing view {dataset_id}.{table_id} before export.")
                # Run the query that defines the view to materialize it
                query = f"SELECT * FROM `{project_id}.{dataset_id}.{table_id}`"

                # Run the query and store the result in a temporary table
                query_job = client.query(query)
                query_job.result()  # Wait for the query to complete
                destination_table_ref = query_job.destination
            else:
                destination_table_ref = table_ref  # It's a regular table, not a view

            destination_uri = (
                f"{chosen_bucket_uri}/{project_id}/{dataset_id}/{table_id}-*.parquet"
            )
            blob_prefix = f"{project_id}/{dataset_id}/{table_id}-"

            # Check if Parquet files already exist
            existing_files = list(bucket.list_blobs(prefix=blob_prefix))
            if existing_files:
                print(f"Skipping {dataset_id}.{table_id}, Parquet files already exist.")
                continue

            # Check schema and cast JSON columns to STRING if needed
            table_schema = client.get_table(destination_table_ref).schema
            json_columns = [
                schema_field.name
                for schema_field in table_schema
                if schema_field.field_type == "JSON"
            ]
            if json_columns:
                print(
                    f"Table {dataset_id}.{table_id} has JSON columns, converting them to STRING for export."
                )
                # Use TO_JSON_STRING for JSON columns
                select_expr = ", ".join(
                    [
                        (
                            f"TO_JSON_STRING({col}) AS {col}"
                            if col in json_columns
                            else col
                        )
                        for col in [field.name for field in table_schema]
                    ]
                )
                query = (
                    f"SELECT {select_expr} FROM `{project_id}.{dataset_id}.{table_id}`"
                )

                # Run the query (BigQuery will create a temporary table for the result)
                query_job = client.query(query)
                query_job.result()  # Wait for the query to complete
                destination_table_ref = query_job.destination

            if args.sample_ratio < 1.0:
                # Downsample the data
                print(
                    f"Sampling {args.sample_ratio * 100}% of data from {dataset_id}.{table_id}"
                )
                query = f"""
                SELECT * FROM `{project_id}.{dataset_id}.{table_id}`
                TABLESAMPLE SYSTEM ({args.sample_ratio * 100} PERCENT)
                """

                # Run the query to sample the data
                query_job = client.query(query)
                query_job.result()  # Wait for the query to complete
                destination_table_ref = query_job.destination

            # Export the sampled result to Parquet
            extract_job_config = bigquery.job.ExtractJobConfig()
            extract_job_config.destination_format = bigquery.DestinationFormat.PARQUET

            extract_job = client.extract_table(
                destination_table_ref, destination_uri, job_config=extract_job_config
            )
            extract_job.result()  # Wait for the job to complete
            print(f"Exported {dataset_id}.{table_id} to {destination_uri}")


if __name__ == "__main__":
    main()
