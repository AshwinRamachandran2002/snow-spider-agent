WITH wages AS (
  SELECT '1998' AS year, AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
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
  UNION ALL
  SELECT '2017' AS year, AVG(avg_wkly_wage_10_total_all_industries) AS avg_weekly_wage
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
cpi AS (
  SELECT CAST(year AS STRING) AS year, AVG(value) AS cpi_value
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_name = 'All items' AND period = 'M13' AND year IN (1998, 2017)
  GROUP BY year
),
growth_rates AS (
  SELECT
    100 * ((w2017.avg_weekly_wage - w1998.avg_weekly_wage) / w1998.avg_weekly_wage) AS Wage_growth_rate,
    100 * ((c2017.cpi_value - c1998.cpi_value) / c1998.cpi_value) AS Inflation_rate
  FROM
    (SELECT * FROM wages WHERE year = '1998') w1998,
    (SELECT * FROM wages WHERE year = '2017') w2017,
    (SELECT * FROM cpi WHERE year = '1998') c1998,
    (SELECT * FROM cpi WHERE year = '2017') c2017
)
SELECT
  ROUND(Wage_growth_rate, 4) AS Wage_growth_rate,
  ROUND(Inflation_rate, 4) AS Inflation_rate
FROM growth_rates;