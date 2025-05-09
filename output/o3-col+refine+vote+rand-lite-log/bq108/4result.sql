WITH filtered_crashes AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                   AS persons_in_crash,
    COUNTIF(injury_severity = 4)                    AS severe_injury_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
  GROUP BY state_number, consecutive_number
  HAVING persons_in_crash > 1                      -- only crashes with >1 person
)
SELECT
  ROUND(
    COUNTIF(severe_injury_cnt > 1) / COUNT(*) * 100.0,
    4
  ) AS percentage_multi_severe_injuries
FROM filtered_crashes;