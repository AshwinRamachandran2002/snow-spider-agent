WITH accident_summary AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                          AS total_persons,
    COUNTIF(injury_severity = 4)                           AS severe_injury_persons
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE
    month_of_crash BETWEEN 1 AND 8        -- January (1) through August (8)
  GROUP BY
    state_number,
    consecutive_number
),
multi_person_accidents AS (
  SELECT *
  FROM accident_summary
  WHERE total_persons > 1              -- accidents with more than one person
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(severe_injury_persons > 1),   -- accidents with >1 severe‑injury persons
      COUNT(*)                              -- all multi‑person accidents in Jan‑Aug
    ) * 100, 
    4                                       -- retain four decimal places
  ) AS percent_with_multiple_severe_injuries
FROM
  multi_person_accidents;