SELECT
  ROUND(
    (
      (wage_2017.annual_wage_2017 - wage_1998.annual_wage_1998) / wage_1998.annual_wage_1998
    ) * 100,
    4
  ) AS Wage_growth_rate,
  ROUND(
    (
      (cpi_2017.cpi_2017 - cpi_1998.cpi_1998) / cpi_1998.cpi_1998
    ) * 100,
    4
  ) AS Inflation_rate
FROM
  (
    SELECT
      (AVG(avg_wkly_wage_10_total_all_industries) * 52) AS annual_wage_1998
    FROM
      (
        SELECT *
        FROM `bigquery-public-data.bls_qcew.1998_q1`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.1998_q2`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.1998_q3`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.1998_q4`
        WHERE area_fips = '42003'
      )
  ) AS wage_1998
CROSS JOIN
  (
    SELECT
      (AVG(avg_wkly_wage_10_total_all_industries) * 52) AS annual_wage_2017
    FROM
      (
        SELECT *
        FROM `bigquery-public-data.bls_qcew.2017_q1`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.2017_q2`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.2017_q3`
        WHERE area_fips = '42003'
        UNION ALL
        SELECT *
        FROM `bigquery-public-data.bls_qcew.2017_q4`
        WHERE area_fips = '42003'
      )
  ) AS wage_2017
CROSS JOIN
  (
    SELECT
      value AS cpi_1998
    FROM
      `bigquery-public-data.bls.cpi_u`
    WHERE
      year = 1998
      AND period = 'M13'
      AND item_name = 'All items'
    LIMIT
      1
  ) AS cpi_1998
CROSS JOIN
  (
    SELECT
      value AS cpi_2017
    FROM
      `bigquery-public-data.bls.cpi_u`
    WHERE
      year = 2017
      AND period = 'M13'
      AND item_name = 'All items'
    LIMIT
      1
  ) AS cpi_2017;