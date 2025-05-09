WITH wage_1998 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS wage
  FROM (
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q1`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q2`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q3`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q4`
  )
  WHERE area_fips = '42003'           -- Allegheny County, PA
),
wage_2017 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS wage
  FROM (
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q1`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q2`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q3`
        UNION ALL
        SELECT area_fips, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q4`
  )
  WHERE area_fips = '42003'
),
cpi_1998 AS (
  SELECT AVG(value) AS cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'      -- All items, U.S. city average
    AND EXTRACT(YEAR FROM date) = 1998
),
cpi_2017 AS (
  SELECT AVG(value) AS cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'
    AND EXTRACT(YEAR FROM date) = 2017
)
SELECT 'average_weekly_wage' AS measure,
       ROUND(100 * ((SELECT wage FROM wage_2017) /
                    (SELECT wage FROM wage_1998) - 1), 2) AS percent_growth
UNION ALL
SELECT 'cpi_all_items' AS measure,
       ROUND(100 * ((SELECT cpi FROM cpi_2017) /
                    (SELECT cpi FROM cpi_1998) - 1), 2) AS percent_growth;