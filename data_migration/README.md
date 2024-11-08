# Spider 2.0 Data Migration
This README briefly describes the data migration process for the Spider 2.0 project. The data migration process is used to move data from BigQuery and SQLite to Snowflake.

## Migration Paths
The data migration process supports the following migration paths:
```plaintext
BigQuery Dataset           SQLite
         |                   |
         v                   v
  BigQuery Engine          Pandas
         |                   |
         |                   v
         |             Local Parquets
         |                   |
          ↘                 ↙
            Parquets in GCS
                    |
                    v
           Snowflake External Stage
                    |
                    v
            Snowflake Tables
```

## Migration Steps
The data migration process consists of the following steps:
1. **Export Data from BigQuery**: Export data from BigQuery to parquet files on GCS. The script will materialize the BigQuery views for exporting to parquet files. Since JSON is not supported in parquet files, the script will also convert JSON columns to string columns.
```bash
python export_bq_to_parquet.py \
    --project <GCP_PROJECT_ID> \
    --bucket <GCS_BUCKET_URI> \
    --eu-bucket <GCS_BUCKET_URI> \
    --input-file <INPUT_FILE> \
    --sample-ratio <SAMPLE_RATIO>
```
The two lists are in `./bq_dataset_lists` and we downsample `githubarchive` to 1% of data. `--eu-bucket` is only required if there are datasets in the EU region. You will need to sync the EU bucket to the main bucket after exporting with `gsutil rsync -r gs://<EU_BUCKET_URI> gs://<GCS_BUCKET_URI>`.

> [!WARNING]
> This step may cause data type conversion issues. Known issues include `JSON` and `POLYGON` types. Please check the data types of the parquet files before proceeding to the next step. Although it's unlikely any data will be lost, but you may need to manually fix the data types in the destination Snowflake tables.

2. **Export Data from SQLite**: Export data from SQLite to local parquet files.
```bash
python export_sqlite_to_parquet.py \
    --dir <SQLITE_DIR> \
    --save_dir <SAVE_DIR>
```

Optionally, before exporting the data, you can preview the SQLite tables using the following command:
```bash
python preview_sqlite_tables.py \
    --dir <SQLITE_DIR>
```

3. **Upload Parquet Files to GCS**: Upload parquet files to GCS.
```bash
gsutil cp -r <LOCAL_PARQUET_DIR> gs://<GCS_BUCKET_URI>/local/
```

4. **Create Snowflake Tables**: The script will automatically handle the creation of Snowflake external stages, parquet file format, and tables with multiple threads. The script uses [INFER_SCHEMA](https://docs.snowflake.com/en/sql-reference/functions/infer_schema) to automatically infer the schema of the parquet files.
```bash
python load_parquet_to_snowflake.py \
    --bucket <GCS_BUCKET_URI> \
    --jsonl-file <MIGRATION_MAP_JSONL> \
    --snowflake-account <SNOWFLAKE_ACCOUNT> \
    --snowflake-user <SNOWFLAKE_USER> \
    --snowflake-password <SNOWFLAKE_PASSWORD> \
    --snowflake-warehouse <SNOWFLAKE_WAREHOUSE> \
    --snowflake-role <SNOWFLAKE_ROLE> \
    --progress-log <PROGRESS_LOG> \
    --error-tolerate \
    --max-workers <MAX_WORKERS>
```

> [!NOTE]
> This script will rename databases, schemas, and tables to case-insensitive names. `-` will be replaced with `_` and names starting with numbers will be prefixed with `_`. Column names, on the other hand, will not be converted and instead quoted with double quotes.

> [!WARNING]
> The script will automatically infer the schema of the parquet files. Althogh the inference is usually correct, there could be cases that the inferred type is not compatible with all the values in the column. If you use the `--error-tolerate` flag, the script will ignore the errors, skip problematic rows, and continue the migration process. Otherwise, the script will raise an error and stop the migration process.
