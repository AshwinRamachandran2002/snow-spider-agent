WITH state_yearly AS (
  SELECT
    SUBSTR(CoC_Number, 1, 2) AS state_abbrev,
    Count_Year,
    SUM(Unsheltered_Homeless) AS total_unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state_abbrev, Count_Year
),
state_pct AS (
  SELECT
    y2015.state_abbrev,
    SAFE_DIVIDE(
      y2018.total_unsheltered - y2015.total_unsheltered,
      y2015.total_unsheltered
    ) * 100 AS pct_change
  FROM state_yearly y2015
  JOIN state_yearly y2018
    ON y2015.state_abbrev = y2018.state_abbrev
   AND y2015.Count_Year = 2015
   AND y2018.Count_Year = 2018
),
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct_change
  FROM state_pct
)
SELECT
  sp.state_abbrev
FROM state_pct sp
CROSS JOIN national_avg na
ORDER BY ABS(sp.pct_change - na.avg_pct_change)
LIMIT 5;