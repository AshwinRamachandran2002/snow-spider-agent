WITH accidents_with_multiple_persons AS (
    SELECT
        "consecutive_number"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2016"
    GROUP BY "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
),
accident_labels AS (
    SELECT
        p."consecutive_number",
        CASE WHEN SUM(CASE WHEN p."injury_severity" = 4 THEN 1 ELSE 0 END) > 1 THEN 1 ELSE 0 END AS "label"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2016" p
    WHERE p."consecutive_number" IN (SELECT "consecutive_number" FROM accidents_with_multiple_persons)
    GROUP BY p."consecutive_number"
),
accident_data AS (
    SELECT
        a."consecutive_number",
        a."state_number",
        a."number_of_drunk_drivers",
        a."day_of_week",
        a."hour_of_crash",
        CASE WHEN a."work_zone" <> 'None' THEN 1 ELSE 0 END AS "work_zone_indicator"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016" a
    WHERE a."consecutive_number" IN (SELECT "consecutive_number" FROM accidents_with_multiple_persons)
),
vehicle_body_type AS (
    SELECT
        v."consecutive_number",
        v."body_type"
    FROM (
        SELECT
            v."consecutive_number",
            v."vehicle_number",
            v."body_type",
            ROW_NUMBER() OVER (PARTITION BY v."consecutive_number" ORDER BY v."vehicle_number") AS rn
        FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016" v
        WHERE v."consecutive_number" IN (SELECT "consecutive_number" FROM accidents_with_multiple_persons)
    ) v
    WHERE v.rn = 1
),
vehicle_speeds AS (
    SELECT
        v."consecutive_number",
        v."vehicle_number",
        ABS(v."travel_speed" - v."speed_limit") AS "speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016" v
    WHERE v."consecutive_number" IN (SELECT "consecutive_number" FROM accidents_with_multiple_persons)
      AND v."travel_speed" <= 150 AND v."travel_speed" NOT IN (997, 998, 999)
      AND v."speed_limit" <= 80 AND v."speed_limit" NOT IN (98, 99)
      AND v."travel_speed" IS NOT NULL AND v."speed_limit" IS NOT NULL
),
accident_speed_diffs AS (
  SELECT
    vs."consecutive_number",
    ROUND(AVG(vs."speed_diff"), 4) AS "avg_speed_diff"
  FROM vehicle_speeds vs
  GROUP BY vs."consecutive_number"
),
accident_speed_levels AS (
  SELECT
    a."consecutive_number",
    CASE
      WHEN sd."avg_speed_diff" >= 0 AND sd."avg_speed_diff" < 20 THEN 0
      WHEN sd."avg_speed_diff" >= 20 AND sd."avg_speed_diff" < 40 THEN 1
      WHEN sd."avg_speed_diff" >= 40 AND sd."avg_speed_diff" < 60 THEN 2
      WHEN sd."avg_speed_diff" >= 60 AND sd."avg_speed_diff" < 80 THEN 3
      WHEN sd."avg_speed_diff" >= 80 THEN 4
      ELSE NULL
    END AS "categorized_speed_difference"
  FROM accidents_with_multiple_persons a
  LEFT JOIN accident_speed_diffs sd ON a."consecutive_number" = sd."consecutive_number"
)
SELECT
    ad."state_number",
    vb."body_type",
    ad."number_of_drunk_drivers",
    ad."day_of_week",
    ad."hour_of_crash",
    ad."work_zone_indicator",
    asl."categorized_speed_difference",
    al."label"
FROM accident_data ad
JOIN accident_labels al ON ad."consecutive_number" = al."consecutive_number"
LEFT JOIN vehicle_body_type vb ON ad."consecutive_number" = vb."consecutive_number"
LEFT JOIN accident_speed_levels asl ON ad."consecutive_number" = asl."consecutive_number";