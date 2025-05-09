WITH state_totals AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state,
    SUM(CASE WHEN `Count_Year` = 2015 THEN `Unsheltered_Homeless` END) AS unsheltered_2015,
    SUM(CASE WHEN `Count_Year` = 2018 THEN `Unsheltered_Homeless` END) AS unsheltered_2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state
),
state_changes AS (
  SELECT
    state,
    SAFE_DIVIDE(COALESCE(unsheltered_2018, 0) - unsheltered_2015, unsheltered_2015) * 100 AS pct_change
  FROM state_totals
  WHERE unsheltered_2015 > 0            -- ensure a valid baseline
),
national_avg AS (
  SELECT AVG(pct_change) AS nat_avg
  FROM state_changes
)
SELECT
  state AS state_abbreviation
FROM state_changes, national_avg
ORDER BY ABS(pct_change - nat_avg)
LIMIT 5;