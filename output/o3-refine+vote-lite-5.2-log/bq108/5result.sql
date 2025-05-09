-- percentage of Jan–Aug 2015 crashes (accidents) that involved
--   1) more than one distinct person, and
--   2) more than one person with severe injuries (injury_severity = 4)

WITH jan_aug_accidents AS (
  SELECT
    state_number,
    consecutive_number
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE
    month_of_crash BETWEEN 1 AND 8            -- January through August
),

person_counts AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                     AS total_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 END)     AS severe_injury_cnt
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  GROUP BY
    state_number,
    consecutive_number
),

eligible_accidents AS (
  SELECT
    a.state_number,
    a.consecutive_number,
    pc.total_persons,
    pc.severe_injury_cnt
  FROM
    jan_aug_accidents AS a
  JOIN
    person_counts   AS pc
  USING (state_number, consecutive_number)
  WHERE
    pc.total_persons > 1                              -- more than one person in crash
)

SELECT
  ROUND( 100.0 *
         SUM(CASE WHEN severe_injury_cnt > 1 THEN 1 ELSE 0 END)
         / COUNT(*)
       , 4) AS percentage_with_multiple_severe_injuries
FROM
  eligible_accidents;