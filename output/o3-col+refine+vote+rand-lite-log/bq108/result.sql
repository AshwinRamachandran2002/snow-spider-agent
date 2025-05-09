-- Percentage of Jan–Aug 2015 accidents with >1 person that also had >1 severe injuries
WITH per_accident AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                       AS person_cnt,
    COUNTIF(injury_severity = 4)                        AS severe_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
  GROUP BY state_number, consecutive_number
),
totals AS (
  SELECT
    SUM(CASE WHEN person_cnt > 1 THEN 1 ELSE 0 END)                         AS accidents_with_multiple_people,
    SUM(CASE WHEN person_cnt > 1 AND severe_cnt > 1 THEN 1 ELSE 0 END)      AS accidents_with_multiple_severe
  FROM per_accident
)
SELECT
  SAFE_DIVIDE(accidents_with_multiple_severe, accidents_with_multiple_people) * 100
    AS pct_with_multiple_severe_injuries
FROM totals;