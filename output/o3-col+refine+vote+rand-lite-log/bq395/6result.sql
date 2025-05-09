/*  Five states whose 2015→2018 % change in unsheltered homelessness is
    closest to the national average of state-level % changes            */

WITH per_state AS (          -- 1. 2015 & 2018 totals by state
  SELECT
    SPLIT(`CoC_Number`, '-')[SAFE_OFFSET(0)] AS state,
    SUM(CASE WHEN `Count_Year` = 2015 THEN `Unsheltered_Homeless` END) AS u15,
    SUM(CASE WHEN `Count_Year` = 2018 THEN `Unsheltered_Homeless` END) AS u18
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state
),
pct AS (                     -- 2. % change for each state
  SELECT
    state,
    100.0 * (u18 - u15) / u15 AS pct_change
  FROM per_state
  WHERE u15 IS NOT NULL AND u18 IS NOT NULL AND u15 <> 0
),
nat AS (                     -- 3. national average of state % changes
  SELECT AVG(pct_change) AS nat_avg
  FROM pct
)
-- 4.  five states closest to the national average
SELECT
  p.state                    -- state abbreviation
FROM pct p
CROSS JOIN nat
ORDER BY ABS(p.pct_change - nat.nat_avg) ASC
LIMIT 5;