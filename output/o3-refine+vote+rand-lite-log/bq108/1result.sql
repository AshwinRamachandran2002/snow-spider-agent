WITH person_data AS (
  SELECT
    state_number,
    consecutive_number,
    person_number,
    injury_severity
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8                     -- January (1) through August (8)
),
accident_stats AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                         AS total_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injuries
  FROM person_data
  GROUP BY state_number, consecutive_number
),
relevant_accidents AS (
  SELECT *
  FROM accident_stats
  WHERE total_persons > 1                                 -- accidents with more than one person
)
SELECT
  ROUND(
    100 * SUM(CASE WHEN severe_injuries > 1 THEN 1 ELSE 0 END) 
        / COUNT(1),                                       -- percentage of those accidents
    4
  ) AS percentage_with_multiple_severe_injuries
FROM relevant_accidents;