import os
import sqlite3
import argparse


def get_table_schemas(db_path):
    """
    Connects to the SQLite database and prints the schema of each table.
    """
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Get the list of tables in the database
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()

        if not tables:
            print(f"No tables found in {db_path}.")
            return

        print(f"Schema for {db_path}:")

        # For each table, print its schema
        for table in tables:
            table_name = table[0]
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = cursor.fetchall()

            print(f"Table: {table_name}")
            print("Columns:")
            for col in columns:
                print(f"  {col[1]} {col[2]}")
            print()

    except sqlite3.Error as e:
        print(f"Error reading {db_path}: {e}")
    finally:
        if conn:
            conn.close()


def find_sqlite_files(dir):
    """
    Recursively searches the directory for .sqlite files and prints the schema of each.
    """
    for root, dirs, files in os.walk(dir):
        for file in files:
            if file.endswith(".sqlite"):
                db_path = os.path.join(root, file)
                get_table_schemas(db_path)


def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Prints the schema of all .sqlite files in a directory."
    )
    parser.add_argument(
        "--dir", type=str, help="The directory to search for .sqlite files."
    )

    # Parse arguments
    args = parser.parse_args()

    # Check if the directory is valid
    if os.path.isdir(args.dir):
        find_sqlite_files(args.dir)
    else:
        print(f"The provided directory '{args.dir}' is not valid.")


if __name__ == "__main__":
    main()
