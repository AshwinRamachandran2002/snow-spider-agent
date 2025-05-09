WITH state_year AS (
  -- total unsheltered homeless by state (derived from first two characters of CoC number) and year
  SELECT
    SUBSTR(`CoC_Number`,1,2)            AS state,
    `Count_Year`                        AS yr,
    SUM(COALESCE(`Unsheltered_Homeless`,0)) AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state, yr
),
state_pivot AS (
  -- pivot to get 2015 and 2018 values side‑by‑side
  SELECT
    state,
    MAX(CASE WHEN yr = 2015 THEN unsheltered END) AS unsheltered_2015,
    MAX(CASE WHEN yr = 2018 THEN unsheltered END) AS unsheltered_2018
  FROM state_year
  GROUP BY state
),
state_change AS (
  -- percentage change per state (exclude states lacking data or with zero in 2015)
  SELECT
    state,
    SAFE_DIVIDE(unsheltered_2018 - unsheltered_2015, unsheltered_2015) * 100 AS pct_change
  FROM state_pivot
  WHERE unsheltered_2015 IS NOT NULL
    AND unsheltered_2018 IS NOT NULL
    AND unsheltered_2015 <> 0
),
national_avg AS (
  -- national average of state percentage changes
  SELECT AVG(pct_change) AS avg_pct_change
  FROM state_change
)
-- five states whose change is closest to the national average
SELECT
  sc.state
FROM state_change sc
CROSS JOIN national_avg na
ORDER BY ABS(sc.pct_change - na.avg_pct_change) ASC
LIMIT 5;