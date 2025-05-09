WITH year_state AS (
  -- total unsheltered homeless persons per state (by first 2‑letter code in CoC_Number) for 2015 & 2018
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state_abbr,
    Count_Year,
    SUM(`Unsheltered_Homeless`) AS unsheltered_total
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state_abbr, Count_Year
),
state_change AS (
  -- compute 2015 → 2018 percentage change for each state
  SELECT
    y15.state_abbr,
    y15.unsheltered_total AS uns2015,
    y18.unsheltered_total AS uns2018,
    SAFE_DIVIDE(y18.unsheltered_total - y15.unsheltered_total,
                y15.unsheltered_total) * 100 AS pct_change
  FROM (SELECT * FROM year_state WHERE Count_Year = 2015) AS y15
  JOIN (SELECT * FROM year_state WHERE Count_Year = 2018) AS y18
  USING (state_abbr)
),
national_avg AS (
  -- national average of state‑level percentage changes
  SELECT
    AVG(pct_change) AS avg_pct_change
  FROM state_change
  WHERE pct_change IS NOT NULL
)
-- find the five states whose change is closest to the national average
SELECT
  sc.state_abbr
FROM
  state_change AS sc
CROSS JOIN
  national_avg AS na
ORDER BY
  ABS(sc.pct_change - na.avg_pct_change) ASC
LIMIT 5;