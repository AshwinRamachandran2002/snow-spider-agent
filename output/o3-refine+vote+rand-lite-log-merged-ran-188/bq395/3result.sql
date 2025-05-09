WITH state_year AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state,
    COUNT_Year,
    SUM(Unsheltered_Homeless) AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE COUNT_Year IN (2015, 2018)
  GROUP BY state, COUNT_Year
),
state_change AS (
  SELECT
    state,
    COALESCE(SUM(CASE WHEN COUNT_Year = 2015 THEN unsheltered END),0) AS unsheltered_2015,
    COALESCE(SUM(CASE WHEN COUNT_Year = 2018 THEN unsheltered END),0) AS unsheltered_2018
  FROM state_year
  GROUP BY state
),
state_pct AS (
  SELECT
    state,
    unsheltered_2015,
    unsheltered_2018,
    SAFE_DIVIDE(unsheltered_2018 - unsheltered_2015, NULLIF(unsheltered_2015,0)) * 100 AS pct_change
  FROM state_change
  WHERE unsheltered_2015 > 0
),
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct_change
  FROM state_pct
),
state_diff AS (
  SELECT
    s.state,
    s.pct_change,
    n.avg_pct_change,
    ABS(s.pct_change - n.avg_pct_change) AS diff_to_avg
  FROM state_pct AS s
  CROSS JOIN national_avg AS n
)
SELECT state
FROM state_diff
ORDER BY diff_to_avg
LIMIT 5;