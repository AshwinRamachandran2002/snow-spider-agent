WITH jan_aug_accidents AS (
  -- 1.  All crashes that happened January‑August 2015
  SELECT
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
accident_level_injury AS (
  -- 2.  Attach every person in those crashes and count
  SELECT
    a.state_number,
    a.consecutive_number,
    COUNT(DISTINCT p.person_number)                                   AS persons_in_crash,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END)            AS severe_injuries
  FROM jan_aug_accidents            AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` p
    USING (state_number, consecutive_number)
  GROUP BY a.state_number, a.consecutive_number
),
multi_person_crashes AS (
  -- 3.  Keep only crashes that involved more than one person
  SELECT *
  FROM accident_level_injury
  WHERE persons_in_crash > 1
)
-- 4.  Compute percentage of those crashes that had >1 person with injury_severity = 4
SELECT
  ROUND(100 * SUM(CASE WHEN severe_injuries > 1 THEN 1 ELSE 0 END)
              / COUNT(*), 4) AS pct_crashes_with_multiple_severe_injuries
FROM multi_person_crashes;