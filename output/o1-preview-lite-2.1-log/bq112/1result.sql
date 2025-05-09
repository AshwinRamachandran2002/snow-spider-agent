WITH wages AS (
  SELECT area_fips, '1998' AS year, avg_wkly_wage_10_total_all_industries
  FROM (
    SELECT * FROM `bigquery-public-data.bls_qcew.1998_q1`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.1998_q2`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.1998_q3`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.1998_q4`
  )
  WHERE area_fips = '42003'
  UNION ALL
  SELECT area_fips, '2017' AS year, avg_wkly_wage_10_total_all_industries
  FROM (
    SELECT * FROM `bigquery-public-data.bls_qcew.2017_q1`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.2017_q2`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.2017_q3`
    UNION ALL
    SELECT * FROM `bigquery-public-data.bls_qcew.2017_q4`
  )
  WHERE area_fips = '42003'
),
avg_wages AS (
  SELECT year, AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
  FROM wages
  GROUP BY year
),
cpi AS (
  SELECT '1998' AS year, AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_code = 'SA0' AND area_code = '0000' AND year = 1998
  UNION ALL
  SELECT '2017' AS year, AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_code = 'SA0' AND area_code = '0000' AND year = 2017
),
results AS (
  SELECT
    ROUND(((w2017.avg_weekly_wage * 52 - w1998.avg_weekly_wage * 52) / (w1998.avg_weekly_wage * 52) * 100), 4) AS Wage_growth_rate,
    ROUND(((c2017.avg_cpi - c1998.avg_cpi) / c1998.avg_cpi * 100), 4) AS Inflation_rate
  FROM
    (SELECT * FROM avg_wages WHERE year = '1998') w1998,
    (SELECT * FROM avg_wages WHERE year = '2017') w2017,
    (SELECT * FROM cpi WHERE year = '1998') c1998,
    (SELECT * FROM cpi WHERE year = '2017') c2017
)
SELECT * FROM results;