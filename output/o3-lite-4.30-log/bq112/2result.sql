WITH wages_1998 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_1998
  FROM (
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q1`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q2`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q3`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.1998_q4`
       )
  WHERE geoid = '42003'          -- Allegheny County, PA
),
wages_2017 AS (
  SELECT AVG(avg_wkly_wage_10_total_all_industries) AS avg_wage_2017
  FROM (
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q1`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q2`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q3`
        UNION ALL
        SELECT geoid, avg_wkly_wage_10_total_all_industries
        FROM `bigquery-public-data.bls_qcew.2017_q4`
       )
  WHERE geoid = '42003'
),
cpi_yearly AS (
  SELECT
    EXTRACT(YEAR FROM date) AS yr,
    AVG(value)              AS avg_cpi
  FROM `bigquery-public-data.bls.cpi_u`
  WHERE series_id = 'CUSR0000SA0'          -- CPI‑U, All items, U.S. city average
    AND EXTRACT(YEAR FROM date) IN (1998, 2017)
  GROUP BY yr
),
calc AS (
  SELECT
    (SELECT avg_wage_1998 FROM wages_1998) AS wage_1998,
    (SELECT avg_wage_2017 FROM wages_2017) AS wage_2017,
    (SELECT avg_cpi FROM cpi_yearly WHERE yr = 1998) AS cpi_1998,
    (SELECT avg_cpi FROM cpi_yearly WHERE yr = 2017) AS cpi_2017
)
SELECT 'wage_growth_pct' AS measure,
       ROUND( (wage_2017 - wage_1998) / wage_1998 * 100, 2) AS percent_growth
FROM calc
UNION ALL
SELECT 'cpi_growth_pct',
       ROUND( (cpi_2017 - cpi_1998) / cpi_1998 * 100, 2)
FROM calc
ORDER BY measure;