WITH wages AS (
  SELECT '1998' AS year, AVG(avg_wkly_wage_10_total_all_industries) * 52 AS annual_wage
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q1` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q2` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q3` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q4` WHERE area_fips = '42003'
  )
  UNION ALL
  SELECT '2017' AS year, AVG(avg_wkly_wage_10_total_all_industries) * 52 AS annual_wage
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q1` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q2` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q3` WHERE area_fips = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q4` WHERE area_fips = '42003'
  )
),
cpi AS (
  SELECT '1998' AS year, value AS cpi_value
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_name = 'All items' AND period = 'M13' AND year = 1998 AND area_name = 'U.S. city average'
  UNION ALL
  SELECT '2017' AS year, value AS cpi_value
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_name = 'All items' AND period = 'M13' AND year = 2017 AND area_name = 'U.S. city average'
)
SELECT
  ROUND(((w17.annual_wage - w98.annual_wage) / w98.annual_wage) * 100, 2) AS Wage_growth_rate,
  ROUND(((c17.cpi_value - c98.cpi_value) / c98.cpi_value) * 100, 2) AS Inflation_rate
FROM
  (SELECT annual_wage FROM wages WHERE year = '1998') w98 CROSS JOIN
  (SELECT annual_wage FROM wages WHERE year = '2017') w17 CROSS JOIN
  (SELECT cpi_value FROM cpi WHERE year = '1998') c98 CROSS JOIN
  (SELECT cpi_value FROM cpi WHERE year = '2017') c17;