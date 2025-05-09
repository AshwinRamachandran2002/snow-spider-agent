WITH person_stats AS (   -- accidents that involve >1 distinct person + fatal count
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                             AS person_cnt,
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                      AS fatal_cnt
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "state_number", "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
),
speed_diff AS (          -- average absolute speed-difference and 0–4 category
    SELECT
        "state_number",
        "consecutive_number",
        CASE
            WHEN AVG(ABS("travel_speed" - "speed_limit")) < 20  THEN 0
            WHEN AVG(ABS("travel_speed" - "speed_limit")) < 40  THEN 1
            WHEN AVG(ABS("travel_speed" - "speed_limit")) < 60  THEN 2
            WHEN AVG(ABS("travel_speed" - "speed_limit")) < 80  THEN 3
            ELSE 4
        END AS "speed_diff_level"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE "travel_speed" <= 151   -- exclude codes 997/998/999
      AND "speed_limit"  <= 80    -- exclude codes 98/99
    GROUP BY "state_number", "consecutive_number"
),
body_type_per_accident AS (       -- one representative body_type per accident
    SELECT
        "state_number",
        "consecutive_number",
        MIN("body_type") AS "body_type"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    GROUP BY "state_number", "consecutive_number"
)

SELECT
    a."state_number",
    bt."body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    CASE WHEN a."work_zone" <> 'None' THEN 1 ELSE 0 END          AS "work_zone_flag",
    sd."speed_diff_level",
    CASE WHEN ps.fatal_cnt > 1 THEN 1 ELSE 0 END                 AS "label"
FROM   NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 a
JOIN   person_stats                  ps ON a."state_number"      = ps."state_number"
                                        AND a."consecutive_number" = ps."consecutive_number"
LEFT  JOIN body_type_per_accident    bt ON a."state_number"      = bt."state_number"
                                        AND a."consecutive_number" = bt."consecutive_number"
LEFT  JOIN speed_diff                sd ON a."state_number"      = sd."state_number"
                                        AND a."consecutive_number" = sd."consecutive_number";