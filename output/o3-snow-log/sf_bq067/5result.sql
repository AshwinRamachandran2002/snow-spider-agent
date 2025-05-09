/*  Labeled data set: accident-vehicle rows with engineered predictors and binary outcome  */
WITH person_counts AS (   -- people and fatality counts per crash
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(*)                                                        AS "persons_involved",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)          AS "fatalities"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "state_number", "consecutive_number"
),
speed_gap AS (            -- average |travel_speed – speed_limit| per crash (valid codes only)
    SELECT
        "state_number",
        "consecutive_number",
        AVG(ABS("travel_speed" - "speed_limit"))                        AS "avg_speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE "travel_speed" BETWEEN 0 AND 151          -- exclude 997, 998, 999 codes
      AND "speed_limit"  BETWEEN 0 AND 80           -- exclude 98, 99 codes
    GROUP BY "state_number", "consecutive_number"
)

SELECT
    a."state_number",
    v."body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    CASE WHEN a."work_zone" <> 'None' THEN 1 ELSE 0 END                 AS "is_work_zone",
    CASE                                                                -- 20-mph buckets
         WHEN s."avg_speed_diff" < 20 THEN 0
         WHEN s."avg_speed_diff" < 40 THEN 1
         WHEN s."avg_speed_diff" < 60 THEN 2
         WHEN s."avg_speed_diff" < 80 THEN 3
         ELSE 4
    END                                                                 AS "speed_diff_level",
    CASE WHEN p."fatalities" > 1 THEN 1 ELSE 0 END                      AS "multi_fatal_label"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 a
JOIN person_counts p   -- keep crashes with >1 person and compute label
  ON a."state_number"       = p."state_number"
 AND a."consecutive_number" = p."consecutive_number"
JOIN speed_gap s       -- add engineered speed-difference feature
  ON a."state_number"       = s."state_number"
 AND a."consecutive_number" = s."consecutive_number"
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 v  -- bring vehicle body type
  ON a."state_number"       = v."state_number"
 AND a."consecutive_number" = v."consecutive_number"
WHERE p."persons_involved" > 1;     -- only accidents with >1 distinct person