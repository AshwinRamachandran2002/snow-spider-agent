WITH person_data AS (
    SELECT "consecutive_number",
           COUNT(DISTINCT "person_number") AS "person_count",
           SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) AS "fatality_count"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
), labeled_data AS (
    SELECT "consecutive_number",
           CASE WHEN "fatality_count" > 1 THEN 1 ELSE 0 END AS "label"
    FROM person_data
), accident_data AS (
    SELECT "consecutive_number",
           "state_number",
           "number_of_drunk_drivers",
           "day_of_week",
           "hour_of_crash",
           CASE WHEN "work_zone" IS NOT NULL AND "work_zone" <> 'None' THEN 1 ELSE 0 END AS "work_zone_indicator"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
), vehicle_speed_data AS (
    SELECT "consecutive_number",
           ABS("travel_speed" - "speed_limit") AS "speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE "travel_speed" IS NOT NULL 
      AND "travel_speed" BETWEEN 0 AND 151
      AND "speed_limit" IS NOT NULL
      AND "speed_limit" BETWEEN 0 AND 80
), avg_speed_diff_per_accident AS (
    SELECT "consecutive_number",
           AVG("speed_diff") AS "avg_speed_diff"
    FROM vehicle_speed_data
    GROUP BY "consecutive_number"
), categorized_speed_diff AS (
    SELECT "consecutive_number",
           CASE 
             WHEN "avg_speed_diff" >= 0 AND "avg_speed_diff" < 20 THEN 0
             WHEN "avg_speed_diff" >= 20 AND "avg_speed_diff" < 40 THEN 1
             WHEN "avg_speed_diff" >= 40 AND "avg_speed_diff" < 60 THEN 2
             WHEN "avg_speed_diff" >= 60 AND "avg_speed_diff" < 80 THEN 3
             ELSE 4
           END AS "categorized_speed_difference"
    FROM avg_speed_diff_per_accident
), vehicle_body_type_data AS (
    SELECT "consecutive_number",
           "body_type",
           COUNT(*) AS "body_type_count"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    GROUP BY "consecutive_number", "body_type"
), accident_body_type AS (
    SELECT "consecutive_number", "body_type"
    FROM (
        SELECT vbt.*,
               ROW_NUMBER() OVER (PARTITION BY "consecutive_number" 
                                  ORDER BY "body_type_count" DESC NULLS LAST, "body_type" ASC) AS "rn"
        FROM vehicle_body_type_data vbt
    ) sub
    WHERE "rn" = 1
)
SELECT 
    a."state_number",
    abt."body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    a."work_zone_indicator",
    csd."categorized_speed_difference",
    l."label"
FROM labeled_data l
JOIN accident_data a ON l."consecutive_number" = a."consecutive_number"
LEFT JOIN categorized_speed_diff csd ON l."consecutive_number" = csd."consecutive_number"
LEFT JOIN accident_body_type abt ON l."consecutive_number" = abt."consecutive_number";