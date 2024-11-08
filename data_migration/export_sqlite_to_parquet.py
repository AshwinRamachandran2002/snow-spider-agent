import os
import argparse
import sqlite3
import pandas as pd


def main():
    parser = argparse.ArgumentParser(
        description="Extract tables from SQLite files and save to Parquet."
    )
    parser.add_argument(
        "--dir", required=True, help="Directory containing SQLite files."
    )
    parser.add_argument(
        "--save_dir", required=True, help="Directory to save Parquet files."
    )
    args = parser.parse_args()

    os.makedirs(args.save_dir, exist_ok=True)

    for file_name in os.listdir(args.dir):
        if file_name.endswith(".sqlite"):
            sqlite_file = os.path.join(args.dir, file_name)
            dataset_name = os.path.splitext(file_name)[0]
            print(f"Processing {sqlite_file}, dataset name: {dataset_name}")

            save_path = os.path.join(args.save_dir, dataset_name)
            os.makedirs(save_path, exist_ok=True)

            conn = sqlite3.connect(sqlite_file)

            # Get list of tables
            tables = pd.read_sql(
                "SELECT name FROM sqlite_master WHERE type='table';", conn
            )

            for table in tables["name"]:
                print(f"Processing table {table}")

                # Read data from the current table using pandas
                df = pd.read_sql(f"SELECT * FROM {table}", conn)

                # Handle missing or problematic values in the dataframe
                for col in df.columns:
                    if df[col].dtype == "object":
                        # Fill NaN or empty values with a default or remove such rows if necessary
                        df[col] = df[col].fillna(
                            ""
                        )  # You can also choose a specific value like 'Unknown'
                        try:
                            # Try converting to a specific type if possible
                            df[col] = df[col].astype(str)
                        except Exception as e:
                            print(
                                f"Warning: Could not convert column {col} to str due to {e}"
                            )

                # Write DataFrame to Parquet
                parquet_file = os.path.join(save_path, f"{table}-000000000000.parquet")
                df.to_parquet(parquet_file, index=False, engine="fastparquet")
                print(f"Saved {parquet_file}")

            conn.close()
            print(
                f"Finished processing SQLite files. Please upload the Parquet files to GCS with `gsutil cp -r {args.save_dir} gs://your-bucket/`"
            )


if __name__ == "__main__":
    main()
