/* Build labelled modelling set for 2016 crashes                    */
WITH person_counts AS (                             -- persons & fatals per crash
  SELECT
    consecutive_number,
    COUNT(DISTINCT person_number)                                           AS person_cnt,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)                    AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY consecutive_number
),
labelled_acc AS (                               -- keep only crashes with >1 person
  SELECT
    consecutive_number,
    CASE WHEN fatal_cnt > 1 THEN 1 ELSE 0 END                             AS label
  FROM person_counts
  WHERE person_cnt > 1
),
/* ---------- vehicle‑level helpers ---------- */
body_type_per_acc AS (                          -- take body_type of first‑listed vehicle
  SELECT
    consecutive_number,
    ARRAY_AGG(body_type ORDER BY vehicle_number LIMIT 1)[OFFSET(0)]        AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY consecutive_number
),
vehicle_speeds AS (                             -- cast speeds / limits to INT64
  SELECT
    consecutive_number,
    SAFE_CAST(travel_speed AS INT64)  AS travel_speed,
    SAFE_CAST(speed_limit  AS INT64)  AS speed_limit
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
),
speed_diff AS (                                 -- avg |speed – limit|  (cleaned)
  SELECT
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit))                                   AS avg_speed_diff
  FROM vehicle_speeds
  WHERE travel_speed IS NOT NULL
        AND speed_limit  IS NOT NULL
        AND travel_speed NOT IN (997, 998, 999)     -- coded / unknown
        AND travel_speed <= 151
        AND speed_limit  NOT IN (98, 99)            -- coded / unknown
        AND speed_limit  <= 80
  GROUP BY consecutive_number
),
speed_diff_binned AS (                          -- bucket into 0‑4 by 20‑mph bands
  SELECT
    consecutive_number,
    CASE
      WHEN avg_speed_diff IS NULL      THEN NULL
      WHEN avg_speed_diff < 20         THEN 0
      WHEN avg_speed_diff < 40         THEN 1
      WHEN avg_speed_diff < 60         THEN 2
      WHEN avg_speed_diff < 80         THEN 3
      ELSE 4
    END                                                                   AS speed_diff_category
  FROM speed_diff
),
/* ---------- accident‑level features ---------- */
accident_feats AS (
  SELECT
    consecutive_number,
    state_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE
      WHEN SAFE_CAST(work_zone AS INT64) = 0 THEN 0
      ELSE 1
    END                                                                 AS work_zone_ind
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)
/* ---------- final labelled data set ---------- */
SELECT
  l.label,
  a.state_number,
  b.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  a.work_zone_ind,
  s.speed_diff_category
FROM labelled_acc          AS l
JOIN accident_feats        AS a USING (consecutive_number)
LEFT JOIN body_type_per_acc AS b USING (consecutive_number)
LEFT JOIN speed_diff_binned AS s USING (consecutive_number);