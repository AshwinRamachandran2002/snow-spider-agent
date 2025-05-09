-- Percentage of Jan–Aug 2015 crashes (with >1 person) that also had >1 severely-injured person
WITH crash_summary AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)            AS persons_in_crash,
    COUNTIF(injury_severity = 4)             AS severe_injured_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8       -- Jan–Aug 2015
  GROUP BY state_number, consecutive_number
),
multi_person AS (
  SELECT *
  FROM crash_summary
  WHERE persons_in_crash > 1                 -- denominator: >1 person involved
)
SELECT
  ROUND(
    100 * COUNTIF(severe_injured_cnt > 1) / COUNT(*)
  , 2
  ) AS percent_with_multiple_severe_injuries
FROM multi_person;