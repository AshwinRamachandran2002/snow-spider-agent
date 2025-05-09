WITH month_stats AS (
  SELECT
    month_of_crash,
    COUNT(DISTINCT person_number)              AS persons_in_month,
    COUNTIF(injury_severity = 4)               AS severe_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8         -- January-August 2015
  GROUP BY month_of_crash
),
multi_person_months AS (
  SELECT *
  FROM month_stats
  WHERE persons_in_month > 1                   -- >1 distinct person
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(severe_injuries > 1),            -- >1 severe injury
      COUNT(*)                                 -- all eligible months
    ),
    4
  ) AS pct_multi_severe_in_multi_person_accidents
FROM multi_person_months;