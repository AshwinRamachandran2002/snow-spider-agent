/* Build a labelled, accident‑level dataset */
WITH
/* ---- aggregate people: count persons & fatalities per crash ---- */
person_agg AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                      AS person_cnt,
    COUNTIF(injury_severity = 4)                       AS fatal_cnt   -- 4 = Fatal Injury
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
/* ---- vehicle info & average |speed – limit| per crash ---------- */
vehicle_agg AS (
  SELECT
    state_number,
    consecutive_number,
    -- choose one body_type (lowest vehicle_number) so the feature is scalar
    ARRAY_AGG(body_type ORDER BY vehicle_number LIMIT 1)[OFFSET(0)] AS body_type,
    AVG(ABS(travel_speed - speed_limit))                            AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151  -- exclude codes 997‑999
    AND speed_limit  BETWEEN 0 AND 80   -- exclude codes 98‑99
  GROUP BY state_number, consecutive_number
),
/* ---- accident‑level predictors straight from accident_2016 ----- */
accident_feats AS (
  SELECT
    state_number,
    consecutive_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE
      WHEN SAFE_CAST(work_zone AS INT64) = 0 THEN 0   -- treat '0' / 0 as “None”
      ELSE 1
    END AS work_zone_flag
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
),
/* ---- bucketise average speed difference into 0‑4 buckets -------- */
speed_level AS (
  SELECT
    state_number,
    consecutive_number,
    body_type,
    CASE
      WHEN avg_speed_diff IS NULL THEN NULL
      WHEN avg_speed_diff < 20   THEN 0
      WHEN avg_speed_diff < 40   THEN 1
      WHEN avg_speed_diff < 60   THEN 2
      WHEN avg_speed_diff < 80   THEN 3
      ELSE 4
    END AS avg_speed_diff_level
  FROM vehicle_agg
)
/* ------------------- final dataset ------------------------------- */
SELECT
  acc.state_number,
  acc.consecutive_number,
  IFNULL(sl.body_type, -1)                    AS body_type,
  acc.number_of_drunk_drivers,
  acc.day_of_week,
  acc.hour_of_crash,
  acc.work_zone_flag,
  sl.avg_speed_diff_level,
  CASE WHEN p.fatal_cnt > 1 THEN 1 ELSE 0 END AS label          -- 1 = >1 fatalities
FROM accident_feats   AS acc
JOIN person_agg       AS p   USING (state_number, consecutive_number)
LEFT JOIN speed_level AS sl  USING (state_number, consecutive_number)
WHERE p.person_cnt > 1;      -- keep crashes with >1 distinct person