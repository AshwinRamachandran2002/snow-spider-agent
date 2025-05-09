-- Five states whose percent change in unsheltered homelessness (2015‑2018)
-- is closest to the national average of state percent changes
WITH state_unshel AS (
  SELECT
    SUBSTR(`CoC_Number`,1,2)               AS state,
    SUM(CASE WHEN `Count_Year` = 2015
             THEN `Unsheltered_Homeless` END) AS u15,
    SUM(CASE WHEN `Count_Year` = 2018
             THEN `Unsheltered_Homeless` END) AS u18
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state
),
state_pct AS (
  SELECT
    state,
    SAFE_DIVIDE(u18 - u15, u15) * 100 AS pct_change
  FROM state_unshel
  WHERE u15 > 0          -- keep states with a 2015 baseline
),
nat_avg AS (
  SELECT AVG(pct_change) AS national_avg_pct_change
  FROM   state_pct
)
SELECT
  sp.state AS state_abbr
FROM state_pct sp
CROSS JOIN nat_avg na
ORDER BY ABS(sp.pct_change - na.national_avg_pct_change)
LIMIT 5;