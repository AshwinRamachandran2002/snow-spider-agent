
class Prompts:
    def __init__(self):
        pass
    def get_condition_onmit_tables(self):
        return ["-- Include all", "-- Omit", "-- Continue", "-- Union all", "-- ...", "-- List all", "-- Replace this", "-- Each table", "-- Add other"]
    def get_prompt_list_all_tables(self, table_struct):
        return f"When performing a UNION operation on many tables, ensure that all table names are explicitly listed. Union first and then add condition and selection. e.g. SELECT \"col1\", \"col2\" FROM (TABLE1 UNION ALL TABLE2) WHERE ...; Don't write sqls as (SELECT col1, col2 FROM TABLE1 WHERE ...) UNION ALL (SELECT col1, col2 FROM TABLE2 WHERE ...); Don't use {self.get_condition_onmit_tables()} to omit any table. Table names here: {table_struct}\n"
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
        return "For string-matching scenarios, if the string is decided, don't use fuzzy query, and avoid using REGEXP. e.g. Get the object's title contains the word \"book\" SQL: WHERE \"title\" LIKE '%book%'\nHowever, if the string is not decided, you may use ILIKE and %. e.g. Get articles that mention \"education\": SQL: \"body\" ILIKE '%education%' OR \"title\" ILIKE '%education%'\n"
    def get_prompt_decimal_places(self):
        return "Keep all decimals to four decimal places.\n"
    def get_prompt_UNION_ALL(self):
        return "When unioning many tables, UNION ALL first and then SELECT and add conditions.\n"
    def get_prompt_convert_symbols(self):
        return "For string-matching scenarios, convert non-standard symbols to '%'. e.g. ('he’s to he%s)\n"
    def get_prompt_filter_null(self):
        return "If the column is not the main part of the answer, there's no need to filter NULL. e.g. Get the name, the trip ID, the ride duration, the start time, the starting station, and the gender of the rider. In this case, no need to filter NULL for the gender of the rider.\n"
    def get_prompt_name(self):
        return "For tasks asking fullname or name, you may combine first name and last name into one column called name.\n"
    def get_prompt_knowledge(self):
        return "Your knowledge is based on information in tables. Don't use your own knowledge.\n"
    def get_prompt_examples(self):
        return "Don't be disturbed by extra description in the task. e.g. When searching tags about Android development, example tags such as 'android-layout', 'android-activity', 'android-intent', and others. In this case, the condition of string matching should be `\"tags\" ILIKE %android%` rather than matching examples.\n"
    def get_prompt_combine_time_range(self):
        return "If the task involves a time range and certain rows can be merged into a single continuous time range, perform the combination. e.g. Merge 00:00:00 - 00:00:20 and 00:00:20 - 00:00:40 into 00:00:00 - 00:00:40."
    def get_prompt_percentage_shown(self):
        return "If the task states that 'The percentage should be shown with %', please add '%' in the answer.\n"