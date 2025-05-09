SELECT
  s.county_name,
  s.state,
  a.median_age,
  a.total_pop,
  ROUND(100000 * CAST(s.confirmed_cases AS FLOAT64) / a.total_pop, 2) AS cases_per_100k,
  ROUND(100000 * CAST(s.deaths AS FLOAT64) / a.total_pop, 2)        AS deaths_per_100k,
  ROUND(100 * CAST(s.deaths AS FLOAT64) /
        NULLIF(CAST(s.confirmed_cases AS FLOAT64), 0), 2)           AS case_fatality_rate_pct
FROM  `bigquery-public-data.covid19_usafacts.summary`              AS s
JOIN  `bigquery-public-data.census_bureau_acs.county_2020_5yr`     AS a
      ON s.county_fips_code = LPAD(a.geo_id, 5, '0')
WHERE s.date      = '2020-08-27'
  AND a.total_pop > 50000
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;