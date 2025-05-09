WITH "person_stats" AS (   -- people per crash + fatal count
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                        AS "num_persons",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                AS "fatal_persons"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2016"
    GROUP BY
        "state_number",
        "consecutive_number"
),
"speed_diff" AS (          -- average |speed-limit| per crash (valid rows only)
    SELECT
        "state_number",
        "consecutive_number",
        AVG(ABS("travel_speed" - "speed_limit"))                              AS "avg_speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016"
    WHERE "travel_speed" BETWEEN 0 AND 151          -- exclude 997-999 codes
      AND "speed_limit"  BETWEEN 0 AND 80           -- exclude 98-99 codes
    GROUP BY
        "state_number",
        "consecutive_number"
)
SELECT
    a."state_number",
    v."body_type",                                -- vehicle-level predictor
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    CASE                                            -- work-zone indicator
        WHEN a."work_zone" IS NULL OR a."work_zone" = 'None' THEN 0
        ELSE 1
    END                                             AS "work_zone_indicator",
    CASE                                            -- binned speed-diff feature
        WHEN sd."avg_speed_diff" IS NULL        THEN NULL
        WHEN sd."avg_speed_diff" < 20           THEN 0
        WHEN sd."avg_speed_diff" < 40           THEN 1
        WHEN sd."avg_speed_diff" < 60           THEN 2
        WHEN sd."avg_speed_diff" < 80           THEN 3
        ELSE                                          4
    END                                             AS "speed_diff_category",
    CASE                                            -- label: >1 fatal persons?
        WHEN ps."fatal_persons" > 1 THEN 1
        ELSE 0
    END                                             AS "label"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016" a
JOIN "person_stats"   ps  ON ps."state_number" = a."state_number"
                          AND ps."consecutive_number" = a."consecutive_number"
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016" v
                          ON v."state_number" = a."state_number"
                          AND v."consecutive_number" = a."consecutive_number"
LEFT JOIN "speed_diff" sd ON sd."state_number" = a."state_number"
                          AND sd."consecutive_number" = a."consecutive_number"
WHERE ps."num_persons" > 1;      -- retain only crashes with >1 person