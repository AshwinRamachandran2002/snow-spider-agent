SELECT
  c.county_name                      AS county,
  c.state                            AS state,
  a.median_age,
  a.total_pop                        AS population,
  ROUND(c._2020_08_27 / a.total_pop * 100000 , 4) AS cases_per_100k,
  ROUND(d._2020_08_27 / a.total_pop * 100000 , 4) AS deaths_per_100k,
  ROUND(SAFE_DIVIDE(d._2020_08_27 , c._2020_08_27) * 100 , 4) AS case_fatality_rate_pct
FROM `bigquery-public-data.covid19_usafacts.confirmed_cases` AS c
JOIN `bigquery-public-data.covid19_usafacts.deaths`          AS d
  ON c.county_fips_code = d.county_fips_code
JOIN `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS a
  ON LPAD(CAST(a.geo_id AS STRING), 5, '0') = c.county_fips_code
WHERE
      a.total_pop > 50000
  AND c._2020_08_27 > 0
ORDER BY
  SAFE_DIVIDE(d._2020_08_27 , c._2020_08_27) DESC,
  c.county_name
LIMIT 3;