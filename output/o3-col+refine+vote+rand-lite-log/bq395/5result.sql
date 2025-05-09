WITH
-- Total unsheltered homeless per state in 2015
y2015 AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state_abbrev,
    SUM(`Unsheltered_Homeless`) AS u2015
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` = 2015
  GROUP BY state_abbrev
),
-- Total unsheltered homeless per state in 2018
y2018 AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state_abbrev,
    SUM(`Unsheltered_Homeless`) AS u2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` = 2018
  GROUP BY state_abbrev
),
-- Percentage change from 2015 to 2018 for each state
pct_change AS (
  SELECT
    y2015.state_abbrev,
    SAFE_DIVIDE(u2018 - u2015, u2015) * 100 AS pct_change
  FROM y2015
  JOIN y2018 USING (state_abbrev)
  WHERE u2015 > 0
),
-- National average of the state percentage changes
nat_avg AS (
  SELECT
    AVG(pc.pct_change) AS national_avg_pct_change
  FROM pct_change AS pc
)
-- Five states whose percentage change is closest to the national average
SELECT
  pc.state_abbrev
FROM pct_change AS pc
CROSS JOIN nat_avg
ORDER BY ABS(pc.pct_change - nat_avg.national_avg_pct_change) ASC
LIMIT 5;