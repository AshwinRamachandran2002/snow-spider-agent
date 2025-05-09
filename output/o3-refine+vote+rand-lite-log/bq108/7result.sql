-- Percentage of Jan–Aug 2015 crashes (with >1 person) that had >1 person
-- suffering a severe injury (injury_severity = 4)
WITH eligible_accidents AS (
  SELECT
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8           -- January–August
),
person_stats AS (
  SELECT
    p.state_number,
    p.consecutive_number,
    COUNT(*) AS person_cnt,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS severe_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` p
  JOIN eligible_accidents e
    ON e.state_number = p.state_number
   AND e.consecutive_number = p.consecutive_number
  GROUP BY p.state_number, p.consecutive_number
),
accidents_with_multiple_people AS (
  SELECT *
  FROM person_stats
  WHERE person_cnt > 1                           -- more than one distinct person
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN severe_cnt > 1 THEN 1 ELSE 0 END),  -- >1 severe injuries
      COUNT(*)                                          -- total eligible crashes
    ) * 100,
    4
  ) AS pct_crashes_with_multiple_severe_injuries
FROM accidents_with_multiple_people;