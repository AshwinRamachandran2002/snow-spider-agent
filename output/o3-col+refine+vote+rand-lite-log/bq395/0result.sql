WITH state_year_totals AS (
  -- total unsheltered homeless per state for 2015 and 2018
  SELECT
    LEFT(`CoC_Number`, 2) AS state,
    `Count_Year`,
    SUM(`Unsheltered_Homeless`) AS unsheltered_total
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state, `Count_Year`
),
pivoted AS (
  -- place 2015 and 2018 totals on the same row
  SELECT
    state,
    MAX(CASE WHEN Count_Year = 2015 THEN unsheltered_total END) AS u2015,
    MAX(CASE WHEN Count_Year = 2018 THEN unsheltered_total END) AS u2018
  FROM state_year_totals
  GROUP BY state
),
state_pct AS (
  -- percentage change for each state
  SELECT
    state,
    SAFE_DIVIDE(u2018 - u2015, u2015) * 100 AS pct_change
  FROM pivoted
  WHERE u2015 IS NOT NULL AND u2018 IS NOT NULL
),
nat_avg AS (
  -- national average of state percentage changes
  SELECT
    AVG(pct_change) AS national_avg_pct_change
  FROM state_pct
)
-- five states whose pct_change is closest to the national average
SELECT
  s.state
FROM
  state_pct AS s
  CROSS JOIN nat_avg AS n
ORDER BY
  ABS(s.pct_change - n.national_avg_pct_change) ASC
LIMIT 5;