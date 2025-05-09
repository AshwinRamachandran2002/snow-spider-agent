WITH yearly_state_totals AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state,
    COUNT_Year AS yr,
    SUM(`Unsheltered_Homeless`) AS unsheltered_cnt
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    COUNT_Year IN (2015, 2018)
  GROUP BY
    state, yr
),
pivoted AS (
  SELECT
    state,
    MAX(CASE WHEN yr = 2015 THEN unsheltered_cnt END) AS u2015,
    MAX(CASE WHEN yr = 2018 THEN unsheltered_cnt END) AS u2018
  FROM
    yearly_state_totals
  GROUP BY
    state
),
state_pct_change AS (
  SELECT
    state,
    SAFE_DIVIDE(u2018 - u2015, NULLIF(u2015, 0)) * 100 AS pct_change
  FROM
    pivoted
  WHERE
    u2015 IS NOT NULL
    AND u2018 IS NOT NULL
    AND u2015 <> 0          -- avoid division‐by‐zero; also removes states with no 2015 count
),
national_avg AS (
  SELECT
    AVG(pct_change) AS avg_change
  FROM
    state_pct_change
)
SELECT
  s.state
FROM
  state_pct_change AS s
CROSS JOIN
  national_avg AS n
ORDER BY
  ABS(s.pct_change - n.avg_change) ASC,
  s.state
LIMIT 5;