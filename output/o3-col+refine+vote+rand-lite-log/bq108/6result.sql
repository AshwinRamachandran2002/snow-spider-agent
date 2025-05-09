-- Percentage of Jan–Aug 2015 crashes with >1 person in which >1 person had a severe injury
SELECT
  ROUND(
    100 * SUM(IF(severe_cnt > 1, 1, 0)) / COUNT(*),
    4
  ) AS pct_multi_severe_injuries
FROM (
  SELECT
    state_number,
    consecutive_number,
    COUNTIF(injury_severity = 4) AS severe_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
  GROUP BY state_number, consecutive_number
  HAVING COUNT(DISTINCT person_number) > 1
);