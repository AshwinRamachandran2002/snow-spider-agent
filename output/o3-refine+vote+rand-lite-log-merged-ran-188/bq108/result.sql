WITH accidents_jan_aug AS (
  -- accidents that happened Jan (1) through Aug (8) 2015
  SELECT
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
person_stats AS (
  -- person counts and severe–injury counts for those accidents
  SELECT
    p.state_number,
    p.consecutive_number,
    COUNT(DISTINCT p.person_number)                    AS total_persons,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` p
  JOIN accidents_jan_aug a
    ON p.state_number = a.state_number
   AND p.consecutive_number = a.consecutive_number
  GROUP BY p.state_number, p.consecutive_number
),
accidents_with_people AS (
  -- keep only accidents that involved >1 distinct person
  SELECT *
  FROM person_stats
  WHERE total_persons > 1
)
SELECT
  ROUND(
        100.0 * SUM(CASE WHEN severe_injuries > 1 THEN 1 ELSE 0 END)
/       COUNT(*)
       ,4
  ) AS pct_accidents_with_multiple_severe_injuries
FROM accidents_with_people;