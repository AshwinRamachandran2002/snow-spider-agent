
SF_EXEC_SQL_QUERY_TEMPLATE = """
import os
import json
import pandas as pd
import snowflake.connector
import csv
import io
import sys

# Load Snowflake credentials
snowflake_credential = json.load(open("./snowflake_credential.json"))

# Connect to Snowflake
conn = snowflake.connector.connect(
    **snowflake_credential
)
cursor = conn.cursor()

# Define the SQL query
sql_query = f\"\"\"


{sql_query}


\"\"\"

# Execute the SQL query
cursor.execute(sql_query)
csv.field_size_limit(sys.maxsize)
try:
    # Fetch the results
    results = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    df = pd.DataFrame(results, columns=columns)
    pd.set_option('display.max_colwidth', None)  # Show full column width

    # Check if the result is empty
    if df.empty:
        print("No data found for the specified query.")
    else:
        # Save or print the results based on the is_save flag
        if {is_save}:
            df.to_csv("{save_path}", index=False)
            print(df.to_csv(index=False))
        else:
            csv_string = (df.to_csv(index=False, header=False))
            rows = list(csv.reader(io.StringIO(csv_string)))
            rows = [",".join([cell.replace('\\n', '') for cell in row]) for row in rows]
            print("\\n".join(rows))

except Exception as e:
    print("Error occurred while fetching data: ", e)
finally:
    cursor.close()
    conn.close()
"""

