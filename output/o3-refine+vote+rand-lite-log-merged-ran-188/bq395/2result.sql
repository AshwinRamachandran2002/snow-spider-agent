WITH state_year AS (
  SELECT
    SUBSTR(`CoC_Number`, 1, 2) AS state_abbrev,
    `Count_Year` AS year,
    SUM(`Unsheltered_Homeless`) AS unsheltered
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    `Count_Year` IN (2015, 2018)
  GROUP BY
    state_abbrev, year
),
state_change AS (
  SELECT
    y15.state_abbrev,
    y15.unsheltered AS unsheltered_2015,
    y18.unsheltered AS unsheltered_2018,
    SAFE_DIVIDE(y18.unsheltered - y15.unsheltered, y15.unsheltered) * 100 AS pct_change
  FROM
    (SELECT * FROM state_year WHERE year = 2015) y15
  JOIN
    (SELECT * FROM state_year WHERE year = 2018) y18
  ON
    y15.state_abbrev = y18.state_abbrev
  WHERE
    y15.unsheltered > 0  -- avoid division by zero
),
national_avg AS (
  SELECT
    AVG(pct_change) AS avg_pct_change
  FROM
    state_change
),
distance_from_avg AS (
  SELECT
    sc.state_abbrev,
    sc.pct_change,
    na.avg_pct_change,
    ABS(sc.pct_change - na.avg_pct_change) AS diff_from_avg
  FROM
    state_change sc
  CROSS JOIN
    national_avg na
)
SELECT
  state_abbrev
FROM
  distance_from_avg
ORDER BY
  diff_from_avg
LIMIT 5;