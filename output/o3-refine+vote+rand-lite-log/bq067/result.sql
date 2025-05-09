WITH person_stats AS (
  /* people and fatally‑injured counts per crash */
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                                AS person_cnt,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)                         AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
labelled_accidents AS (
  /* crashes with >1 person; label =1 if >1 fatality */
  SELECT
    state_number,
    consecutive_number,
    CASE WHEN fatal_cnt > 1 THEN 1 ELSE 0 END                                    AS label
  FROM person_stats
  WHERE person_cnt > 1
),
speed_diff AS (
  /* average |travel_speed – speed_limit| per crash, after filtering codes      */
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit))                                         AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed IS NOT NULL
        AND speed_limit  IS NOT NULL
        AND travel_speed NOT IN (997, 998, 999)
        AND travel_speed <= 151
        AND speed_limit  NOT IN (98, 99)
        AND speed_limit  <= 80
  GROUP BY state_number, consecutive_number
),
body_type_per_accident AS (
  /* representative body_type: lowest numeric code in the crash                */
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type)                                                               AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
)
SELECT
  la.label,                                           -- target variable
  a.state_number,
  bt.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  /* work‑zone indicator (1 = not “None”) – cast protects against type mismatch */
  CASE WHEN CAST(a.work_zone AS STRING) = '0' THEN 0 ELSE 1 END                  AS work_zone_ind,
  /* bucketised average speed difference: 0‑4 (20‑mph bands)                   */
  CASE
       WHEN sd.avg_speed_diff IS NULL              THEN NULL
       ELSE LEAST(4, CAST(FLOOR(sd.avg_speed_diff / 20) AS INT64))
  END                                                 AS avg_speed_diff_cat
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
JOIN labelled_accidents                  AS la
  ON a.state_number       = la.state_number
 AND a.consecutive_number = la.consecutive_number
LEFT JOIN body_type_per_accident         AS bt
  ON a.state_number       = bt.state_number
 AND a.consecutive_number = bt.consecutive_number
LEFT JOIN speed_diff                     AS sd
  ON a.state_number       = sd.state_number
 AND a.consecutive_number = sd.consecutive_number;