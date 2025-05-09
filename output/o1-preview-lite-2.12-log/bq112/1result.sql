WITH wages AS (
  SELECT '1998' AS year, AVG(avg_wkly_wage) AS avg_wage
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries AS avg_wkly_wage
    FROM `bigquery-public-data.bls_qcew.1998_q1` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q2` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q3` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.1998_q4` WHERE geoid = '42003'
  )
  UNION ALL
  SELECT '2017' AS year, AVG(avg_wkly_wage) AS avg_wage
  FROM (
    SELECT avg_wkly_wage_10_total_all_industries AS avg_wkly_wage
    FROM `bigquery-public-data.bls_qcew.2017_q1` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q2` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q3` WHERE geoid = '42003'
    UNION ALL
    SELECT avg_wkly_wage_10_total_all_industries FROM `bigquery-public-data.bls_qcew.2017_q4` WHERE geoid = '42003'
  )
),
cpi AS (
  SELECT CAST(year AS STRING) AS year, AVG(value) AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE item_name = 'All items' AND period = 'M13' AND year IN (1998, 2017)
  GROUP BY year
)
SELECT
  ROUND(((w2017.avg_wage - w1998.avg_wage) / w1998.avg_wage) * 100, 2) AS Wage_growth_rate,
  ROUND(((c2017.avg_cpi - c1998.avg_cpi) / c1998.avg_cpi) * 100, 2) AS Inflation_rate
FROM
  (SELECT avg_wage FROM wages WHERE year = '1998') w1998
  CROSS JOIN (SELECT avg_wage FROM wages WHERE year = '2017') w2017
  CROSS JOIN (SELECT avg_cpi FROM cpi WHERE year = '1998') c1998
  CROSS JOIN (SELECT avg_cpi FROM cpi WHERE year = '2017') c2017