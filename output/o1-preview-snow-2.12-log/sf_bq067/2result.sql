WITH person_summary AS (
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number") AS "person_count",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) AS "fatality_count"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "state_number", "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
),
person_label AS (
    SELECT
        "state_number",
        "consecutive_number",
        CASE WHEN "fatality_count" > 1 THEN 1 ELSE 0 END AS "label"
    FROM person_summary
),
vehicle_speed AS (
    SELECT
        "state_number",
        "consecutive_number",
        ABS("travel_speed" - "speed_limit") AS "speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE 
        "travel_speed" < 151 AND "travel_speed" NOT IN (997, 998, 999) AND
        "speed_limit" < 80 AND "speed_limit" NOT IN (98, 99) AND
        "travel_speed" IS NOT NULL AND "speed_limit" IS NOT NULL
),
accident_speed_diff AS (
    SELECT
        "state_number",
        "consecutive_number",
        AVG("speed_diff") AS "avg_speed_diff"
    FROM vehicle_speed
    GROUP BY "state_number", "consecutive_number"
),
vehicle_body_type AS (
    SELECT
        "state_number",
        "consecutive_number",
        "body_type",
        COUNT(*) AS "body_type_count",
        ROW_NUMBER() OVER (
            PARTITION BY "state_number", "consecutive_number"
            ORDER BY COUNT(*) DESC NULLS LAST, "body_type" NULLS LAST
        ) AS rn
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    GROUP BY "state_number", "consecutive_number", "body_type"
),
vehicle_body_type_top AS (
    SELECT
        "state_number",
        "consecutive_number",
        "body_type"
    FROM vehicle_body_type
    WHERE rn = 1
),
accident_data AS (
    SELECT
        "state_number",
        "consecutive_number",
        "number_of_drunk_drivers",
        "day_of_week",
        "hour_of_crash",
        CASE WHEN "work_zone" IS NOT NULL AND "work_zone" <> 'None' THEN 1 ELSE 0 END AS "work_zone_indicator"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
)
SELECT
    a."state_number",
    vbt."body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    a."work_zone_indicator",
    CASE
        WHEN asd."avg_speed_diff" >= 0 AND asd."avg_speed_diff" < 20 THEN 0
        WHEN asd."avg_speed_diff" >= 20 AND asd."avg_speed_diff" < 40 THEN 1
        WHEN asd."avg_speed_diff" >= 40 AND asd."avg_speed_diff" < 60 THEN 2
        WHEN asd."avg_speed_diff" >= 60 AND asd."avg_speed_diff" < 80 THEN 3
        WHEN asd."avg_speed_diff" >= 80 THEN 4
        ELSE NULL
    END AS "categorized_speed_difference",
    pl."label"
FROM person_label pl
LEFT JOIN accident_data a
    ON pl."state_number" = a."state_number" AND pl."consecutive_number" = a."consecutive_number"
LEFT JOIN vehicle_body_type_top vbt
    ON pl."state_number" = vbt."state_number" AND pl."consecutive_number" = vbt."consecutive_number"
LEFT JOIN accident_speed_diff asd
    ON pl."state_number" = asd."state_number" AND pl."consecutive_number" = asd."consecutive_number"
ORDER BY a."state_number" NULLS LAST, a."consecutive_number" NULLS LAST;