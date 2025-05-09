WITH crash_stats AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number) AS persons_in_crash,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injured
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
  GROUP BY
    state_number,
    consecutive_number
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(persons_in_crash > 1 AND severe_injured > 1),
      COUNTIF(persons_in_crash > 1)
    ) * 100,
    4
  ) AS pct_multi_person_crashes_with_multi_severe
FROM crash_stats;