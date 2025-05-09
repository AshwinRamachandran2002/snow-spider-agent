WITH base AS (
  SELECT
    per.state_number,
    per.consecutive_number,
    COUNT(DISTINCT per.person_number)                   AS person_cnt,
    COUNTIF(per.injury_severity = 4)                    AS sev_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`  per
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` acc
    USING (state_number, consecutive_number)
  WHERE acc.month_of_crash BETWEEN 1 AND 8
  GROUP BY per.state_number, per.consecutive_number
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
            COUNTIF(person_cnt > 1 AND sev_cnt > 1),
            COUNTIF(person_cnt > 1)
         ), 4
  ) AS percentage
FROM base;