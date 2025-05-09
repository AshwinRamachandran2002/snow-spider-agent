-- percentage of Jan–Aug 2015 accidents (with >1 person) that had >1 severe‑injury victims
WITH jan_aug_accidents AS (
  SELECT state_number, consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
accident_person_stats AS (
  SELECT
    p.state_number,
    p.consecutive_number,
    COUNT(DISTINCT p.person_number)                             AS total_persons,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END)      AS severe_injury_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` p
  JOIN jan_aug_accidents a
    ON a.state_number = p.state_number
   AND a.consecutive_number = p.consecutive_number
  GROUP BY p.state_number, p.consecutive_number
),
multi_person_accidents AS (
  SELECT *
  FROM accident_person_stats
  WHERE total_persons > 1
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN severe_injury_count > 1 THEN 1 ELSE 0 END),
      COUNT(*)
    ) * 100,
    4
  ) AS percentage_with_multiple_severe_injuries
FROM multi_person_accidents;