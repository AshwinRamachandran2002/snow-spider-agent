WITH state_year AS (
  SELECT
    SUBSTR(CoC_Number, 1, 2) AS state,
    Count_Year,
    SUM(Unsheltered_Homeless) AS unsheltered
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE Count_Year IN (2015, 2018)
  GROUP BY state, Count_Year
),
state_change AS (
  SELECT
    state,
    MAX(CASE WHEN Count_Year = 2015 THEN unsheltered END) AS unsheltered_2015,
    MAX(CASE WHEN Count_Year = 2018 THEN unsheltered END) AS unsheltered_2018
  FROM state_year
  GROUP BY state
),
state_pct AS (
  SELECT
    state,
    SAFE_DIVIDE(unsheltered_2018 - unsheltered_2015, unsheltered_2015) AS pct_change
  FROM state_change
  WHERE unsheltered_2015 IS NOT NULL
    AND unsheltered_2018 IS NOT NULL
    AND unsheltered_2015 > 0
),
national_avg AS (
  SELECT AVG(pct_change) AS nat_avg FROM state_pct
),
ranked_states AS (
  SELECT
    s.state AS state_abbreviation,
    ABS(s.pct_change - n.nat_avg) AS diff_from_avg,
    ROW_NUMBER() OVER (ORDER BY ABS(s.pct_change - n.nat_avg)) AS rn
  FROM state_pct s
  CROSS JOIN national_avg n
)
SELECT state_abbreviation
FROM ranked_states
WHERE rn <= 5
ORDER BY rn;