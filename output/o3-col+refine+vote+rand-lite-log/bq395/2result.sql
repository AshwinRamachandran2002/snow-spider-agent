WITH yr15 AS (
  SELECT 
    SUBSTR(`CoC_Number`, 1, 2) AS state_code,
    SUM(`Unsheltered_Homeless`) AS total_2015
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` = 2015
  GROUP BY state_code
),
yr18 AS (
  SELECT 
    SUBSTR(`CoC_Number`, 1, 2) AS state_code,
    SUM(`Unsheltered_Homeless`) AS total_2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` = 2018
  GROUP BY state_code
),
pct AS (
  SELECT
    COALESCE(yr15.state_code, yr18.state_code) AS state_code,
    SAFE_DIVIDE(total_2018 - total_2015, total_2015) * 100 AS pct_change
  FROM yr15
  FULL JOIN yr18 USING (state_code)
),
national AS (
  SELECT AVG(pct_change) AS nat_avg
  FROM pct
)
SELECT 
  p.state_code
FROM pct AS p
CROSS JOIN national AS n
ORDER BY ABS(p.pct_change - n.nat_avg)
LIMIT 5;