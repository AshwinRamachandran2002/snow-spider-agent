SELECT
  s.county_name                                       AS county,
  s.state,
  c.median_age,
  c.total_pop,
  ROUND( (CAST(s.confirmed_cases AS FLOAT64) / c.total_pop) * 100000, 1) AS cases_per_100k,
  ROUND( (CAST(s.deaths          AS FLOAT64) / c.total_pop) * 100000, 1) AS deaths_per_100k,
  ROUND( SAFE_DIVIDE(CAST(s.deaths AS FLOAT64), CAST(s.confirmed_cases AS FLOAT64)) * 100, 2 ) 
        AS case_fatality_rate_pct
FROM   `bigquery-public-data.covid19_usafacts.summary`        AS s
JOIN   `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS c
       ON s.county_fips_code = LPAD(c.geo_id, 5, '0')
WHERE  s.date = '2020-08-27'
  AND  c.total_pop > 50000
ORDER  BY case_fatality_rate_pct DESC
LIMIT  3;