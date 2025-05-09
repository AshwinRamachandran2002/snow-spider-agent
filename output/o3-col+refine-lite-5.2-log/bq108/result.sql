/*  Percentage of Jan‑Aug 2015 accidents that:
      – involved more than one distinct person
      – had more than one person with severe injuries (injury_severity = 4)
*/

WITH per_accident AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                 AS person_cnt,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)          AS severe_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8      -- January through August
  GROUP BY state_number, consecutive_number
)

SELECT
  SUM(CASE WHEN person_cnt > 1 THEN 1 ELSE 0 END)                         AS accidents_gt1_person,
  SUM(CASE WHEN person_cnt > 1 AND severe_cnt > 1 THEN 1 ELSE 0 END)      AS accidents_gt1_person_gt1_severe,
  ROUND(
        100 * SUM(CASE WHEN person_cnt > 1 AND severe_cnt > 1 THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN person_cnt > 1 THEN 1 ELSE 0 END), 0)
        , 2)                                                              AS pct_with_multiple_severe_injuries
FROM per_accident;