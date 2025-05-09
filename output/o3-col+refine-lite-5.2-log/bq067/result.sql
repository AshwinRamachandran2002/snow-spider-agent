/* Build accident‑level dataset, fix work_zone comparison (STRING) */
WITH person_summary AS (
  SELECT
    consecutive_number,
    COUNT(DISTINCT person_number)                       AS n_persons,
    COUNTIF(injury_severity = 4)                        AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY consecutive_number
  HAVING n_persons > 1                                  -- keep only multi‑person crashes
),
/* avg |travel_speed – speed_limit|, after removing code values */
speed_stats AS (
  SELECT
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_abs_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151                  -- exclude 997/8/9
    AND speed_limit  BETWEEN 0 AND 80                   -- exclude 98/99
  GROUP BY consecutive_number
),
speed_bucket AS (
  SELECT
    consecutive_number,
    CASE
      WHEN avg_abs_diff IS NULL THEN NULL
      WHEN avg_abs_diff < 20  THEN 0
      WHEN avg_abs_diff < 40  THEN 1
      WHEN avg_abs_diff < 60  THEN 2
      WHEN avg_abs_diff < 80  THEN 3
      ELSE                       4
    END AS speed_diff_bucket
  FROM speed_stats
),
/* one representative body_type per crash */
vehicle_body AS (
  SELECT
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY consecutive_number
),
/* accident‑level predictors, use correct STRING comparison for work_zone */
accident_feats AS (
  SELECT
    consecutive_number,
    state_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE WHEN work_zone = 'None' OR work_zone IS NULL THEN 0 ELSE 1 END AS work_zone_flag
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)

SELECT
  ps.consecutive_number,
  CASE WHEN ps.fatal_cnt > 1 THEN 1 ELSE 0 END AS label,
  af.state_number,
  vb.body_type,
  af.number_of_drunk_drivers,
  af.day_of_week,
  af.hour_of_crash,
  af.work_zone_flag,
  sb.speed_diff_bucket
FROM person_summary   ps
JOIN accident_feats   af USING (consecutive_number)
LEFT JOIN vehicle_body vb USING (consecutive_number)
LEFT JOIN speed_bucket sb USING (consecutive_number);