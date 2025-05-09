WITH state_totals AS (
  SELECT
    SUBSTR(CoC_Number, 1, 2) AS state,
    SUM(CASE WHEN Count_Year = 2015 THEN Unsheltered_Homeless END) AS u2015,
    SUM(CASE WHEN Count_Year = 2018 THEN Unsheltered_Homeless END) AS u2018
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    Count_Year IN (2015, 2018)
  GROUP BY
    state
  HAVING
    u2015 > 0
),
state_change AS (
  SELECT
    state,
    SAFE_DIVIDE(u2018 - u2015, u2015) * 100 AS pct_change
  FROM state_totals
),
national_avg AS (
  SELECT
    AVG(pct_change) AS avg_pct_change
  FROM state_change
)
SELECT
  sc.state AS state_abbreviation
FROM
  state_change sc
  CROSS JOIN national_avg na
ORDER BY
  ABS(sc.pct_change - na.avg_pct_change),
  sc.state
LIMIT 5;