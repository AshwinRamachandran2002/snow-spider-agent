-- Top 3 U.S. counties (population > 50k) with the highest COVID-19
-- case-fatality rate on 27-Aug-2020
SELECT
  TRIM(c.county_name)                                 AS county,
  c.state,
  pop.median_age,
  pop.total_pop,
  ROUND((c._2020_08_27 / pop.total_pop) * 100000 , 1) AS cases_per_100k,
  ROUND((d._2020_08_27 / pop.total_pop) * 100000 , 1) AS deaths_per_100k,
  ROUND((d._2020_08_27 / c._2020_08_27) * 100 , 2)    AS case_fatality_rate_pct
FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`  AS pop
JOIN `bigquery-public-data.covid19_usafacts.confirmed_cases`    AS c
  ON LPAD(pop.geo_id, 5, '0') = c.county_fips_code
JOIN `bigquery-public-data.covid19_usafacts.deaths`             AS d
  ON c.county_fips_code = d.county_fips_code
WHERE pop.total_pop > 50000          -- Only counties with >50,000 residents
  AND c._2020_08_27 IS NOT NULL
  AND d._2020_08_27 IS NOT NULL
  AND c._2020_08_27 > 0              -- Avoid divide-by-zero
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;