-- Build the requested accident-level labelled dataset (corrected comparison for work_zone)
WITH person_stats AS (
  -- 1) People counts and fatal-injury counts per crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                          AS person_cnt,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)   AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING person_cnt > 1                                    -- keep only crashes with >1 person
),
speed_diff AS (
  -- 2) Average |travel_speed − speed_limit| per crash, valid codes only
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151      -- exclude 997–999
    AND speed_limit BETWEEN 5 AND 80        -- exclude 98–99
  GROUP BY state_number, consecutive_number
),
speed_cat AS (
  -- 3) Bucket the average speed difference into 20-mph bands (0–4)
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_speed_diff < 20 THEN 0
      WHEN avg_speed_diff < 40 THEN 1
      WHEN avg_speed_diff < 60 THEN 2
      WHEN avg_speed_diff < 80 THEN 3
      ELSE 4
    END AS speed_diff_cat
  FROM speed_diff
),
vehicle_body AS (
  -- 4) Representative vehicle body_type for each crash (smallest code present)
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
),
acc AS (
  -- 5) Core accident-level predictors
  SELECT
    state_number,
    consecutive_number,
    day_of_week,
    hour_of_crash,
    work_zone,
    number_of_drunk_drivers
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)

-- 6) Assemble final labelled dataset
SELECT
  ps.state_number,
  ps.consecutive_number,
  vb.body_type,
  acc.number_of_drunk_drivers,
  acc.day_of_week,
  acc.hour_of_crash,
  -- work_zone indicator: 1 if not "None"/0, else 0
  CASE
    WHEN SAFE_CAST(acc.work_zone AS INT64) = 0 OR acc.work_zone IS NULL THEN 0
    ELSE 1
  END AS work_zone_ind,
  sc.speed_diff_cat,
  -- label: 1 if >1 fatal injuries, else 0
  IF(ps.fatal_cnt > 1, 1, 0) AS label
FROM person_stats       AS ps
JOIN acc                USING (state_number, consecutive_number)
LEFT JOIN vehicle_body  AS vb USING (state_number, consecutive_number)
LEFT JOIN speed_cat     AS sc USING (state_number, consecutive_number);