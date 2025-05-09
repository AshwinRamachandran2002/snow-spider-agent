WITH per_state AS (
  SELECT
    SUBSTR(`CoC_Number`, 0, 2) AS state_abbr,
    SUM(CASE WHEN `Count_Year` = 2015 THEN `Unsheltered_Homeless` END) AS total_2015,
    SUM(CASE WHEN `Count_Year` = 2018 THEN `Unsheltered_Homeless` END) AS total_2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state_abbr
),
pct_change AS (
  SELECT
    state_abbr,
    SAFE_DIVIDE(total_2018 - total_2015, total_2015) * 100 AS pct_change
  FROM per_state
),
national_avg AS (
  SELECT
    AVG(p.pct_change) AS avg_pct_change
  FROM pct_change AS p
)
SELECT
  p.state_abbr
FROM pct_change AS p
CROSS JOIN national_avg AS a
ORDER BY ABS(p.pct_change - a.avg_pct_change)
LIMIT 5;