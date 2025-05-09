-- Did Allegheny County (FIPS 42003) wages keep up with CPI inflation, 1998‑2017?
WITH wage_1998 AS (
  SELECT
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_1998
  FROM
    `bigquery-public-data.bls_qcew.1998_q*`
  WHERE
    geoid = '42003'                                   -- Allegheny County, PA
),
wage_2017 AS (
  SELECT
    AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_2017
  FROM
    `bigquery-public-data.bls_qcew.2017_q*`
  WHERE
    geoid = '42003'
),
cpi_1998 AS (
  SELECT
    AVG(value) AS cpi_1998                            -- annual average CPI‑U, all items
  FROM
    `bigquery-public-data.bls.cpi_u`
  WHERE
    series_id = 'CUSR0000SA0'
    AND year = 1998
),
cpi_2017 AS (
  SELECT
    AVG(value) AS cpi_2017
  FROM
    `bigquery-public-data.bls.cpi_u`
  WHERE
    series_id = 'CUSR0000SA0'
    AND year = 2017
),
combined AS (
  SELECT
    w98.avg_wage_1998,
    w17.avg_wage_2017,
    c98.cpi_1998,
    c17.cpi_2017
  FROM wage_1998 w98
  CROSS JOIN wage_2017 w17
  CROSS JOIN cpi_1998 c98
  CROSS JOIN cpi_2017 c17
)
SELECT
  ROUND((avg_wage_2017 - avg_wage_1998) / avg_wage_1998 * 100, 2) AS wage_growth_percent,
  ROUND((cpi_2017 - cpi_1998) / cpi_1998 * 100, 2)               AS cpi_growth_percent,
  CASE
    WHEN (avg_wage_2017 - avg_wage_1998) / avg_wage_1998 >=
         (cpi_2017 - cpi_1998) / cpi_1998
      THEN 'Yes'
    ELSE 'No'
  END AS wages_kept_pace_with_inflation
FROM combined;