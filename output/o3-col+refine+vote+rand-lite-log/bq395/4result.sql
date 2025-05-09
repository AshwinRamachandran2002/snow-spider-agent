WITH state_totals AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state,
    SUM(CASE WHEN `Count_Year` = 2015 THEN `Unsheltered_Homeless` END) AS unsheltered_2015,
    SUM(CASE WHEN `Count_Year` = 2018 THEN `Unsheltered_Homeless` END) AS unsheltered_2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state
),
pct_change AS (
  SELECT
    state,
    100.0 * (unsheltered_2018 - unsheltered_2015) / NULLIF(unsheltered_2015, 0) AS pct_change_15_18
  FROM state_totals
),
national_avg AS (
  SELECT AVG(pct_change_15_18) AS avg_pct_change FROM pct_change
)
SELECT
  p.state
FROM pct_change AS p
CROSS JOIN national_avg AS n
ORDER BY ABS(p.pct_change_15_18 - n.avg_pct_change)
LIMIT 5;