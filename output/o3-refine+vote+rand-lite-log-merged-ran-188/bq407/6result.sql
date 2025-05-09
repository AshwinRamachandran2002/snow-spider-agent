-- Top three counties (pop > 50k) with the highest COVID-19 case-fatality rates
-- on 27-Aug-2020, plus key 2020 ACS demographics
SELECT
  TRIM(c.county_name)                                    AS county,
  c.state,
  pop.median_age,
  pop.total_pop,
  ROUND(SAFE_DIVIDE(c._2020_08_27 , pop.total_pop) * 100000, 1) AS cases_per_100k,
  ROUND(SAFE_DIVIDE(d._2020_08_27 , pop.total_pop) * 100000, 1) AS deaths_per_100k,
  ROUND(SAFE_DIVIDE(d._2020_08_27 , c._2020_08_27) * 100, 2)    AS case_fatality_rate_pct
FROM   `bigquery-public-data.covid19_usafacts.confirmed_cases`  AS c
JOIN   `bigquery-public-data.covid19_usafacts.deaths`           AS d
       ON  c.county_fips_code = d.county_fips_code
JOIN   `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS pop
       ON  pop.geo_id = c.county_fips_code
WHERE  pop.total_pop > 50000        -- only counties with >50k residents
  AND  c._2020_08_27  > 0           -- avoid divide-by-zero
ORDER BY
  case_fatality_rate_pct DESC
LIMIT 3;