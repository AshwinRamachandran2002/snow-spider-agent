/*  Labeled accident-level dataset for 2016 NHTSA fatal crashes           */
/*  – keeps crashes that involve >1 distinct person                      */
/*  – label = 1 if more than one person suffered a fatal injury (K-code) */
/*  – predictors: state_number, body_type, number_of_drunk_drivers,      */
/*                day_of_week, hour_of_crash, in_work_zone,              */
/*                speed_diff_level                                       */

WITH person_stats AS (      -- how many people & fatals in each crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                         AS person_cnt,
    COUNTIF(injury_severity = 4)                          AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING person_cnt > 1                                   -- keep >1 person
),
labels AS (                 -- binary label
  SELECT
    state_number,
    consecutive_number,
    CASE WHEN fatal_cnt > 1 THEN 1 ELSE 0 END AS label
  FROM person_stats
),
vehicle_body AS (           -- representative body-type per crash
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
),
speed_diff AS (             -- avg |speed − limit| then bucket to 0-4
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_diff < 20 THEN 0
      WHEN avg_diff < 40 THEN 1
      WHEN avg_diff < 60 THEN 2
      WHEN avg_diff < 80 THEN 3
      ELSE 4
    END AS speed_diff_level
  FROM (
    SELECT
      state_number,
      consecutive_number,
      AVG(ABS(travel_speed - speed_limit)) AS avg_diff
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
    WHERE travel_speed BETWEEN 0 AND 151      -- exclude 997/998/999
      AND speed_limit  BETWEEN 5 AND 80       -- exclude 0/98/99
    GROUP BY state_number, consecutive_number
  )
)

SELECT
  a.state_number,
  vb.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  CASE WHEN a.work_zone = 'None' OR a.work_zone IS NULL THEN 0 ELSE 1 END AS in_work_zone,
  sd.speed_diff_level,
  l.label
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` a
JOIN labels        AS l  USING (state_number, consecutive_number)
LEFT JOIN vehicle_body AS vb USING (state_number, consecutive_number)
LEFT JOIN speed_diff   AS sd USING (state_number, consecutive_number);