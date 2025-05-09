WITH per_accident AS (
  SELECT
    state_number,
    consecutive_number,
    MAX(month_of_crash)                         AS month_of_crash,
    COUNT(DISTINCT person_number)               AS persons_involved,
    SUM(CASE WHEN injury_severity = 4 THEN 1 END) AS severe_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  GROUP BY state_number, consecutive_number
)

SELECT
  SAFE_DIVIDE(
      COUNTIF(severe_injuries > 1),   -- accidents with >1 severe injury
      COUNT(*)                        -- all accidents (Jan–Aug) with >1 person
  ) * 100 AS percentage_with_multiple_severe_injuries
FROM per_accident
WHERE month_of_crash BETWEEN 1 AND 8      -- January through August
  AND persons_involved  > 1;              -- more than one distinct person