WITH state_year AS (
  SELECT
    SUBSTR(CoC_Number, 1, 2) AS state_abbr,
    Count_Year,
    SUM(Unsheltered_Homeless) AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state_abbr, Count_Year
),
pivot AS (
  SELECT
    state_abbr,
    MAX(IF(Count_Year = 2015, unsheltered, NULL)) AS unsheltered_2015,
    MAX(IF(Count_Year = 2018, unsheltered, NULL)) AS unsheltered_2018
  FROM state_year
  GROUP BY state_abbr
),
pct_change_state AS (
  SELECT
    state_abbr,
    SAFE_DIVIDE(unsheltered_2018 - unsheltered_2015, unsheltered_2015) * 100 AS pct_change
  FROM pivot
  WHERE unsheltered_2015 IS NOT NULL
    AND unsheltered_2018 IS NOT NULL
    AND unsheltered_2015 <> 0
),
national_avg AS (
  SELECT AVG(pct_change) AS avg_pct_change
  FROM pct_change_state
),
state_distance AS (
  SELECT
    s.state_abbr,
    s.pct_change,
    n.avg_pct_change,
    ABS(s.pct_change - n.avg_pct_change) AS distance_to_avg
  FROM pct_change_state s
  CROSS JOIN national_avg n
)
SELECT
  state_abbr
FROM state_distance
ORDER BY distance_to_avg ASC, state_abbr
LIMIT 5;