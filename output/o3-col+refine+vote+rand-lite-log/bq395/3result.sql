WITH state_totals AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2)                    AS state_abbrev,
    SUM(CASE WHEN `Count_Year` = 2015
             THEN `Unsheltered_Homeless` END)    AS unsheltered_2015,
    SUM(CASE WHEN `Count_Year` = 2018
             THEN `Unsheltered_Homeless` END)    AS unsheltered_2018
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE `Count_Year` IN (2015, 2018)
  GROUP BY state_abbrev
),
state_changes AS (
  SELECT
    state_abbrev,
    SAFE_DIVIDE(unsheltered_2018 - unsheltered_2015,
                unsheltered_2015)               AS pct_change
  FROM state_totals
  WHERE unsheltered_2015 > 0
),
avg_change AS (
  SELECT AVG(pct_change) AS national_avg
  FROM state_changes
),
closest_states AS (
  SELECT
    sc.state_abbrev,
    ABS(sc.pct_change - ac.national_avg) AS distance_from_avg
  FROM state_changes sc
  CROSS JOIN avg_change ac
  ORDER BY distance_from_avg
  LIMIT 5
)
SELECT state_abbrev
FROM closest_states
ORDER BY distance_from_avg;