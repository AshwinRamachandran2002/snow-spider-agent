-- Did Allegheny County’s average annual wages (all industries) grow as fast as CPI-U (all items)?
WITH wage_quarters AS (
  -- Grab each quarter of 1998 & 2017 for Allegheny County (FIPS 42003)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64)               AS yr,
    avg_wkly_wage_10_total_all_industries                    AS wage
  FROM  `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('1998_q1','1998_q2','1998_q3','1998_q4',
                          '2017_q1','2017_q2','2017_q3','2017_q4')
    AND area_fips = '42003'
),
annual_wage AS (
  SELECT yr, AVG(wage) AS avg_wage
  FROM   wage_quarters
  GROUP  BY yr
),
annual_cpi AS (
  -- Monthly CPI-U (all items, U.S. city avg, seasonally adjusted)
  SELECT year AS yr, AVG(value) AS avg_cpi
  FROM   `bigquery-public-data.bls.cpi_u`
  WHERE  series_id = 'CUSR0000SA0'
    AND  year IN (1998, 2017)
  GROUP  BY yr
),
numbers AS (
  SELECT
    (SELECT avg_wage FROM annual_wage WHERE yr = 1998) AS wage_1998,
    (SELECT avg_wage FROM annual_wage WHERE yr = 2017) AS wage_2017,
    (SELECT avg_cpi  FROM annual_cpi  WHERE yr = 1998) AS cpi_1998,
    (SELECT avg_cpi  FROM annual_cpi  WHERE yr = 2017) AS cpi_2017
)
SELECT
  ROUND( (wage_2017 - wage_1998) / wage_1998 * 100 , 2) AS wage_growth_pct,
  ROUND( (cpi_2017  - cpi_1998)  / cpi_1998  * 100 , 2) AS cpi_growth_pct,
  CASE
    WHEN (wage_2017 - wage_1998) / wage_1998 >= (cpi_2017 - cpi_1998) / cpi_1998
    THEN 'Yes — wages kept pace with inflation'
    ELSE 'No — wages did NOT keep pace with inflation'
  END AS wages_kept_pace_with_inflation
FROM numbers;