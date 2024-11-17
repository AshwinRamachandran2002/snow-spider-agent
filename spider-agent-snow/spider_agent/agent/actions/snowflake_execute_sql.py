import re
from dataclasses import field
from typing import Optional

from .action import Action


class SnowflakeExecuteSQL(Action):
    action_type: str = field(
        default="execute_snowflake_SQL",
        init=False,
        repr=False,
        metadata={"help": 'type of action, c.f., "exec_sf_sql"'},
    )
    sql_query: str = field(metadata={"help": "SQL query to execute"})
    is_save: bool = field(metadata={"help": "whether to save result to CSV"})
    save_path: str = field(
        default=None,
        metadata={"help": "path where the output CSV file is saved if is_save is True"},
    )

    @classmethod
    def get_action_description(cls) -> str:
        return """
## SnowflakeExecuteSQL Action
* Signature: SnowflakeExecuteSQL(sql_query="SELECT * FROM your_table", is_save=True, save_path="/workspace/output_file.csv")
* Description: Executes a SQL query on Snowflake. If `is_save` is True, the results are saved to a specified CSV file; otherwise, results are printed.
If you estimate that the number of returned rows is small, you can set is_save=False, to directly view the results. If you estimate that the number of returned rows is large, be sure to set is_save = True.
The `save_path` CSV must be under the `/workspace` directory.
* Examples:
  - Example1: SnowflakeExecuteSQL(sql_query="SELECT count(*) FROM sales", is_save=False)
  - Example2: SnowflakeExecuteSQL(sql_query="SELECT user_id, sum(purchases) FROM transactions GROUP BY user_id", is_save=True, save_path="/workspace/result.csv")
"""

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional["SnowflakeExecuteSQL"]:
        pattern = r"""
            SnowflakeExecuteSQL\(
                \s*sql_query\s*=\s*
                (?P<quote_sql>\"\"\"|\"|\'\'\'|\'|\"\"\")  # Match opening quote for sql_query
                (?P<sql_query>.*?)
                (?<!\\)(?P=quote_sql)                      # Match closing quote for sql_query
                ,\s*is_save\s*=\s*
                (?P<is_save>True|False)
                (?:,\s*save_path\s*=\s*
                    (?P<quote_path>\"\"\"|\"|\'\'\'|\'|\"\"\")  # Match opening quote for save_path
                    (?P<save_path>.*?)
                    (?<!\\)(?P=quote_path)                     # Match closing quote for save_path
                )?
                \s*\)
        """
        # Use re.VERBOSE to allow multiline and commented pattern
        match = re.search(pattern, text, flags=re.DOTALL | re.VERBOSE)
        if match:
            # Extracting sql_query
            sql_query_raw = match.group("sql_query")
            sql_query = (
                sql_query_raw.replace(r"\"", '"')
                .replace(r"\'", "'")
                .replace("\\\\", "\\")
            )

            # Extracting is_save
            is_save_str = match.group("is_save")
            is_save = is_save_str.strip().lower() == "true"

            # Extracting save_path if present
            save_path = ""
            if match.group("save_path"):
                save_path_raw = match.group("save_path")
                save_path = (
                    save_path_raw.replace(r"\"", '"')
                    .replace(r"\'", "'")
                    .replace("\\\\", "\\")
                )

            return cls(sql_query=sql_query, is_save=is_save, save_path=save_path)
        return None

    def __repr__(self) -> str:
        save_info = f', save_path="{self.save_path}"' if self.is_save else ""
        return f'SnowflakeExecuteSQL(sql_query="{self.sql_query}", is_save={self.is_save}{save_info})'
