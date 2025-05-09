/* Create a labeled dataset of 2016 crashes that involve >1 distinct person.
   Each output row corresponds to one vehicle in such crashes and contains
   the requested predictors plus the binary label (1 = >1 fatalities). */

WITH person_agg AS (         -- 1. crashes with >1 person + fatality count
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                         AS person_cnt,
    COUNTIF(injury_severity = 4)                          AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING person_cnt > 1
),
speed_diff AS (              -- 2. avg |travel_speed − speed_limit| per crash
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit))                  AS avg_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0  AND 151     -- exclude 997-999
    AND speed_limit    BETWEEN 5  AND 80     -- exclude 98-99
  GROUP BY state_number, consecutive_number
),
accident_base AS (           -- 3. accident-level predictors
  SELECT
    state_number,
    consecutive_number,
    day_of_week,
    hour_of_crash,
    number_of_drunk_drivers,
    CASE WHEN work_zone = 'None' THEN 0 ELSE 1 END        AS work_zone_ind
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)

-- 4. assemble final dataset
SELECT
  ab.state_number,
  ab.consecutive_number,
  v.body_type,
  ab.number_of_drunk_drivers,
  ab.day_of_week,
  ab.hour_of_crash,
  ab.work_zone_ind,
  CASE                                              -- bucketised speed diff
    WHEN sd.avg_diff IS NULL  THEN NULL
    WHEN sd.avg_diff < 20     THEN 0
    WHEN sd.avg_diff < 40     THEN 1
    WHEN sd.avg_diff < 60     THEN 2
    WHEN sd.avg_diff < 80     THEN 3
    ELSE 4
  END                                               AS speed_diff_bucket,
  CASE WHEN p.fatal_cnt > 1 THEN 1 ELSE 0 END       AS label
FROM accident_base                                   AS ab
JOIN person_agg                                      AS p
  ON ab.state_number      = p.state_number
 AND ab.consecutive_number = p.consecutive_number
LEFT JOIN speed_diff                                 AS sd
  ON ab.state_number      = sd.state_number
 AND ab.consecutive_number = sd.consecutive_number
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016` AS v
  ON ab.state_number      = v.state_number
 AND ab.consecutive_number = v.consecutive_number;