WITH wages_1998 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_1998
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q1`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q2`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q3`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.1998_q4`
    WHERE geoid = '42003'
  )
),
wages_2017 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_2017
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q1`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q2`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q3`
    WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries
    FROM `bigquery-public-data.bls_qcew.2017_q4`
    WHERE geoid = '42003'
  )
),
cpi_1998 AS (
  SELECT AVG(value) AS avg_cpi_1998
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE year = 1998 AND LOWER(item_name) = 'all items' AND area_name = 'U.S. city average'
),
cpi_2017 AS (
  SELECT AVG(value) AS avg_cpi_2017
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE year = 2017 AND LOWER(item_name) = 'all items' AND area_name = 'U.S. city average'
)
SELECT
  ROUND(((wages_2017.avg_wage_2017 - wages_1998.avg_wage_1998) / wages_1998.avg_wage_1998) * 100, 4) AS Wage_growth_rate,
  ROUND(((cpi_2017.avg_cpi_2017 - cpi_1998.avg_cpi_1998) / cpi_1998.avg_cpi_1998) * 100, 4) AS Inflation_rate
FROM wages_1998, wages_2017, cpi_1998, cpi_2017;