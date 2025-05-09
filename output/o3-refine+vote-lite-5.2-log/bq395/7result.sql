WITH per_state_year AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2)                     AS state,
    CAST(Count_Year AS INT64)                      AS year,
    SUM(Unsheltered_Homeless)                      AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state, year
),
state_pivot AS (
  SELECT
    state,
    MAX(CASE WHEN year = 2015 THEN unsheltered END) AS u2015,
    MAX(CASE WHEN year = 2018 THEN unsheltered END) AS u2018
  FROM per_state_year
  GROUP BY state
),
state_change AS (
  SELECT
    state,
    u2015,
    u2018,
    SAFE_DIVIDE(u2018 - u2015, u2015) * 100 AS pct_change
  FROM state_pivot
  WHERE u2015 IS NOT NULL
    AND u2018 IS NOT NULL
    AND u2015 <> 0
),
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct
  FROM state_change
)
SELECT
  sc.state
FROM state_change sc
CROSS JOIN national_avg na
ORDER BY ABS(sc.pct_change - na.avg_pct)
LIMIT 5;