
class Prompts:
    def __init__(self):
        pass
    def get_condition_onmit_tables(self):
        return ["-- Include all", "-- Omit", "-- Continue", "-- Union all", "-- ...", "-- List all", "-- Replace this", "-- Each table", "-- Add other"]
    def get_prompt_dialect_list_all_tables(self, table_struct, api):
        if api == "snowflake" or "sqlite":
            return f"When performing a UNION operation on many tables, ensure that all table names are explicitly listed. Union first and then add condition and selection. e.g. SELECT \"col1\", \"col2\" FROM (TABLE1 UNION ALL TABLE2) WHERE ...; Don't write sqls as (SELECT col1, col2 FROM TABLE1 WHERE ...) UNION ALL (SELECT col1, col2 FROM TABLE2 WHERE ...); Don't use {self.get_condition_onmit_tables()} to omit any table. Table names here: {table_struct}\n"
        if api == "bigquery":
            return "When performing a UNION operation on many tables with similar prefix, you can use a wildcard table to simplify your query. e.g., SELECT col1, col2 FROM `project_id.dataset_id.table_prefix*` WHERE _TABLE_SUFFIX IN ('table1_suffix', 'table2_suffix');. Avoid manually listing tables unless absolutely necessary.\n"
    def get_prompt_quantile_duration(self):
        return "For 50 min durations divided into 10 quantiles, it's about time not distance, so calculate distance every 5 minutes. When calculating the average number of sth, no need to filter null values, as they'll be treated as 0.\n"
    # def get_prompt_quantile_trip(self):
    #     return "For trips partition, it's about distance not time, so calculate minutes in equal divided trips.\n"
    def get_prompt_package(self):
        return "It's acceptable that there are repetitive names and versions in NPM package.\n"
    def get_prompt_generator(self):
        return "Be careful of using GENERATOR. Don't use seq4(), use ROW_NUMBER().\n"
    def get_prompt_NPM_package(self):
        return "For NPM packages, the result can contain repetitive names and versions.\n"
    def get_prompt_ST_INTERSECTS_FUNC(self):
        return "Usage of ST_INTERSECTS: ST_INTERSECTS(geometry1, ST_GEOGFROMWKB(geometry2)) This function checks if the two geometries intersect. The first argument, geometry1, is compared with the second argument, geometry2, which is converted from its WKB (Well-Known Binary) representation to a geography type using ST_GEOGFROMWKB. If the two geometries share any portion of space, the function returns TRUE; otherwise, it returns FALSE. Usage of ST_CONTAINS: ST_CONTAINS(r1.geometry, r2.geometry) This function checks if the geometry r1.geometry completely contains the geometry r2.geometry. It returns TRUE if all points of r2.geometry are within r1.geometry and FALSE otherwise. This is useful for spatial containment queries, such as verifying whether one region is entirely within another. ARRAY_INTERSECTION(nodes1, nodes2): This function computes the intersection of the two arrays, returning a new array containing only the elements that are present in both nodes1 and nodes2. ARRAY_SIZE(...): This function then determines the size (or number of elements) in the resulting array from the intersection.\n"
    def get_prompt_trip_duration(self):
        return "Calculation of trip duration in date range (A, B): pickup_datetime in (A, B) and dropoff_datetime in (A, B), not only pickup_datetime.\n"
    def get_prompt_full_outer_join(self):
        return "Avoid using FULL OUTER JOIN\n"
    def get_prompt_no_fuzzy_query(self):
        return "For string-matching scenarios, if the string is decided, don't use fuzzy query, and avoid using REGEXP. e.g. Get the object's title contains the word \"book\" SQL: WHERE \"title\" LIKE '%book%'\n"
    def get_prompt_fuzzy_query(self):
        return "For string-matching scenarios, if the string is decided, don't use fuzzy query, and avoid using REGEXP. e.g. Get the object's title contains the word \"book\"\nHowever, if the string is not decided, you may use fuzzy query and ignore upper or lower case. e.g. Get articles that mention \"education\".\n"
    def get_prompt_decimal_places(self):
        return "If the task description does not specify the number of decimal places, retain all decimals to four places.\n"
    def get_prompt_UNION_ALL(self):
        return "When unioning many tables, UNION ALL first and then SELECT and add conditions.\n"
    def get_prompt_convert_symbols(self):
        return "For string-matching scenarios, convert non-standard symbols to '%'. e.g. ('he’s to he%s)\n"
    def get_prompt_filter_null(self):
        return "If the column is not the main part of the answer, there's no need to filter NULL. e.g. Get the name, the trip ID, the ride duration, the start time, the starting station, and the gender of the rider. In this case, no need to filter NULL for the gender of the rider.\n"
    def get_prompt_name(self):
        return "For tasks asking fullname or name, you should combine first name and last name into one column called name. Format: ```csv\nname\nname:str```\n"
    def get_prompt_knowledge(self):
        return "Your knowledge is based on information in tables. Don't use your own knowledge.\n"
    def get_prompt_examples(self):
        return "Don't be disturbed by extra description in the task. e.g. When searching tags about Android development, example tags such as 'android-layout', 'android-activity', 'android-intent', and others. In this case, the condition of string matching should be `\"tags\" ILIKE %android%` rather than matching examples.\n"
    def get_prompt_combine_time_range(self):
        return "If the task involves a time range and certain rows can be merged into a single continuous time range, perform the combination. e.g. Merge 00:00:00 - 00:00:20 and 00:00:20 - 00:00:40 into 00:00:00 - 00:00:40."
    def get_prompt_percentage_shown(self):
        return "If the task states that 'The percentage should be shown with %', please add '%' in the answer.\n"
    def get_prompt_dialect_nested(self, api):
        if api == "snowflake":
            return "For columns in json nested format: e.g. SELECT t.\"column_name\", f.value::VARIANT:\"key_name\"::STRING AS \"abstract_text\" FROM PATENTS.PATENTS.PUBLICATIONS t, LATERAL FLATTEN(input => t.\"json_column_name\") f; DO NOT directly answer the task and ensure all column names are enclosed in double quotations. For nested columns like event_params, when you don't know the structure of it, first watch the whole column: SELECT f.value FROM table, LATERAL FLATTEN(input => t.\"event_params\") f;\n"
        elif api == "bigquery":
            return "Extract a specific key from a nested JSON column: SELECT t.\"column_name\", JSON_EXTRACT_SCALAR(f.value, \"$.key_name\") AS \"abstract_text\" FROM `database.schema.table` AS t, UNNEST(JSON_EXTRACT_ARRAY(t.\"json_column_name\")) AS f;\nWhen the structure of the nested column (e.g., event_params) is unknown, first inspect the whole column: SELECT f.value FROM `project.dataset.table` AS t, UNNEST(JSON_EXTRACT_ARRAY(t.\"event_params\")) AS f;\n"
        elif api == "sqlite":
            return "Extract a specific key from a nested JSON column: SELECT t.\"column_name\", json_extract(f.value, '$.key_name') AS \"abstract_text\" FROM \"table_name\" AS t, json_each(t.\"json_column_name\") AS f;\nWhen the structure of the nested column (e.g., event_params) is unknown, first inspect the whole column: SELECT f.value FROM \"table_name\" AS t, json_each(t.\"event_params\") AS f;\n"
        else:
            return "Unsupported API. Please provide a valid API name ('snowflake', 'bigquery', 'sqlite')."
    def get_prompt_dialect_basic(self, api):
        if api == "snowflake":
            return "```sql\nSELECT \"COLUMN_NAME\" FROM DATABASE.SCHEMA.TABLE WHERE ... ``` (Adjust \"DATABASE\", \"SCHEMA\", and \"TABLE\" to match actual names, ensure all column names are enclosed in double quotations)"
        elif api == "bigquery":
            return "```sql\nSELECT `column_name` FROM `database.schema.table` WHERE ... ``` (Replace `database`, `schema`, and `table` with actual names. Enclose column names and table identifiers with backticks.)"
        elif api == "sqlite":
            return "```sql\nSELECT DISTINCT \"column_name\" FROM \"table_name\" WHERE ... ``` (Replace \"table_name\" with the actual table name. Enclose table and column names with double quotations if they contain special characters or match reserved keywords.)"
        else:
            return "Unsupported API. Please provide a valid API name ('snowflake', 'bigquery', 'sqlite')."
    def get_prompt_dialect_string_matching(self, api):
        if api == "snowflake":
            return "Don't directly match strings if you are not convinced. Use fuzzy query first: WHERE str ILIKE \"%target_str%\" For string matching, e.g. meat lovers, you should use % to replace space. e.g. ILKIE %meat%lovers%.\n"
        elif api == "bigquery":
            return "Don't directly match strings if you are not convinced. Use LOWER for fuzzy queries: WHERE LOWER(str) LIKE LOWER('%target_str%'). For example, to match 'meat lovers', use LOWER(str) LIKE '%meat%lovers%'.\n"
        elif api == "sqlite":
            return "Don't directly match strings if you are not convinced. For fuzzy queries, use: WHERE str LIKE '%target_str%'. For example, to match 'meat lovers', use WHERE str LIKE '%meat%lovers%'. If case sensitivity is needed, add COLLATE BINARY: WHERE str LIKE '%target_str%' COLLATE BINARY.\n"
        else:
            return "Unsupported API. Please provide a valid API name ('snowflake', 'bigquery', 'sqlite')."