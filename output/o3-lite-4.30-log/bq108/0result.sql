WITH jan_aug_crashes AS (
  SELECT state_number, consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
people AS (
  SELECT p.state_number,
         p.consecutive_number,
         p.person_number,
         p.injury_severity
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` AS p
  JOIN jan_aug_crashes AS a
    ON p.state_number = a.state_number
   AND p.consecutive_number = a.consecutive_number
),
crash_level AS (
  SELECT state_number,
         consecutive_number,
         COUNT(DISTINCT person_number)        AS person_cnt,
         COUNTIF(injury_severity = 4)         AS severe_cnt
  FROM people
  GROUP BY state_number, consecutive_number
),
totals AS (
  SELECT
    COUNTIF(person_cnt > 1)                                AS total_multi_person_crashes,
    COUNTIF(person_cnt > 1 AND severe_cnt > 1)             AS crashes_with_multi_severe
  FROM crash_level
)
SELECT ROUND(
         SAFE_DIVIDE(crashes_with_multi_severe,
                     total_multi_person_crashes) * 100, 4
       ) AS percentage
FROM totals;