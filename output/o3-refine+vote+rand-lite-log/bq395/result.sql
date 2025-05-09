WITH state_year AS (
  -- total unsheltered homeless per state (by first two letters of CoC number) for 2015 & 2018
  SELECT
    SUBSTR(CoC_Number, 1, 2)           AS state_abbr,
    Count_Year                         AS yr,
    SUM(Unsheltered_Homeless)          AS unsheltered_total
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state_abbr, yr
),
state_pivot AS (
  -- pivot to have 2015 and 2018 columns
  SELECT
    state_abbr,
    MAX(CASE WHEN yr = 2015 THEN unsheltered_total END) AS unsheltered_2015,
    MAX(CASE WHEN yr = 2018 THEN unsheltered_total END) AS unsheltered_2018
  FROM state_year
  GROUP BY state_abbr
),
state_change AS (
  -- percentage change per state
  SELECT
    state_abbr,
    (unsheltered_2018 - unsheltered_2015) * 100.0 / NULLIF(unsheltered_2015, 0) AS pct_change
  FROM state_pivot
  WHERE unsheltered_2015 IS NOT NULL
    AND unsheltered_2018 IS NOT NULL
    AND unsheltered_2015 <> 0
),
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct_change
  FROM state_change
)
-- five states whose change is closest to national average
SELECT
  sc.state_abbr
FROM state_change sc
CROSS JOIN national_avg na
ORDER BY ABS(sc.pct_change - na.avg_pct_change) ASC, sc.state_abbr
LIMIT 5;