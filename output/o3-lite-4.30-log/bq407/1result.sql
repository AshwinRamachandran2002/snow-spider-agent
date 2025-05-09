SELECT
  TRIM(cc.county_name)                         AS county,
  cc.state                                     AS state,
  ca.median_age                                AS median_age,
  CAST(ca.total_pop AS INT64)                  AS population,
  ROUND(1e5 * cc._2020_08_27 / ca.total_pop,4) AS cases_per_100k,
  ROUND(1e5 * cd._2020_08_27 / ca.total_pop,4) AS deaths_per_100k,
  ROUND(100 * cd._2020_08_27 / NULLIF(cc._2020_08_27,0),4) 
                                               AS case_fatality_rate_pct
FROM `bigquery-public-data.covid19_usafacts.confirmed_cases` AS cc
JOIN `bigquery-public-data.covid19_usafacts.deaths`           AS cd
  USING (county_fips_code)
JOIN `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS ca
  ON LPAD(ca.geo_id,5,'0') = cc.county_fips_code
WHERE ca.total_pop > 50000          -- only counties with population > 50,000
  AND cc._2020_08_27 > 0            -- avoid divide‑by‑zero
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;