-- Percentage of Jan–Aug 2015 crashes (with >1 person) that had >1 person
-- suffering a severe injury (injury_severity = 4)

WITH qualifying_accidents AS (          -- denominator set
  SELECT consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
    AND (number_of_forms_submitted_for_persons_not_in_motor_vehicles +
         number_of_forms_submitted_for_persons_in_motor_vehicles) > 1
),
injury_counts AS (                      -- count severe injuries per crash
  SELECT
    p.consecutive_number,
    COUNTIF(p.injury_severity = 4) AS severe_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` AS p
  JOIN qualifying_accidents qa
    ON p.consecutive_number = qa.consecutive_number
  GROUP BY p.consecutive_number
),
summary AS (
  SELECT
    (SELECT COUNT(*) FROM qualifying_accidents)                         AS total_accidents,
    (SELECT COUNT(*) FROM injury_counts WHERE severe_injuries > 1)      AS multi_severe_accidents
)
SELECT
  multi_severe_accidents,
  total_accidents,
  ROUND(SAFE_DIVIDE(multi_severe_accidents, total_accidents) * 100, 4) AS pct_multi_severe_injury_accidents
FROM summary;