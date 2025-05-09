/* ------------------------------------------------------------
   Build a labeled crash-level data set (rows = accident–vehicle)
   ------------------------------------------------------------ */
WITH person_stats AS (          -- persons & fatalities per crash
    SELECT 
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                            AS "person_cnt",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                    AS "fatal_cnt"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2016"
    GROUP BY "consecutive_number"
), speed_gap AS (               -- avg │speed – limit│ per crash (clean ranges only)
    SELECT
        "consecutive_number",
        AVG(ABS("travel_speed" - "speed_limit"))                                  AS "avg_abs_speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016"
    WHERE "travel_speed" BETWEEN 0 AND 151      -- remove coded 997-999
      AND "speed_limit"  BETWEEN 0 AND 80       -- remove coded  98-99
    GROUP BY "consecutive_number"
), accidents AS (               -- essential crash-level variables
    SELECT
        "consecutive_number",
        "state_number",
        "number_of_drunk_drivers",
        "day_of_week",
        "hour_of_crash",
        CASE WHEN "work_zone" <> 'None' THEN 1 ELSE 0 END                        AS "work_zone_flag"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016"
)
SELECT
    a."consecutive_number",
    a."state_number",
    v."body_type"                                                              AS "vehicle_body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    a."work_zone_flag",
    /* bucket the average absolute speed difference into 0-4 (20-mph steps) */
    CASE
        WHEN sg."avg_abs_speed_diff" IS NULL          THEN NULL
        WHEN sg."avg_abs_speed_diff" <  20            THEN 0
        WHEN sg."avg_abs_speed_diff" <  40            THEN 1
        WHEN sg."avg_abs_speed_diff" <  60            THEN 2
        WHEN sg."avg_abs_speed_diff" <  80            THEN 3
        ELSE                                             4
    END                                                                     AS "speed_diff_bucket",
    /* label: 1 ⇢ >1 fatalities; 0 ⇢ ≤1 fatality (crash has >1 persons by WHERE) */
    CASE WHEN ps."fatal_cnt" > 1 THEN 1 ELSE 0 END                           AS "label"
FROM accidents               a
JOIN person_stats            ps  ON a."consecutive_number" = ps."consecutive_number"
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016" v
                                ON a."consecutive_number" = v."consecutive_number"
LEFT JOIN speed_gap          sg  ON a."consecutive_number" = sg."consecutive_number"
WHERE ps."person_cnt" > 1;          -- keep only crashes that involve >1 distinct person