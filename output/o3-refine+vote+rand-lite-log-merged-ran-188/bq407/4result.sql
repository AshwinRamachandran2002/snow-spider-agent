-- Top 3 U.S. counties (pop > 50k) with the highest COVID-19 case-fatality rates on 2020-08-27
SELECT
  cc.county_name                           AS county,
  cc.state                                 AS state,
  c2020.median_age                         AS median_age,
  c2020.total_pop                          AS total_population,
  ROUND(SAFE_DIVIDE(cc._2020_08_27 , c2020.total_pop) * 100000, 1) AS cases_per_100k,
  ROUND(SAFE_DIVIDE(cd._2020_08_27 , c2020.total_pop) * 100000, 1) AS deaths_per_100k,
  ROUND(SAFE_DIVIDE(cd._2020_08_27 , cc._2020_08_27) * 100, 2)    AS case_fatality_rate_pct
FROM  `bigquery-public-data.census_bureau_acs.county_2020_5yr`      AS c2020
JOIN  `bigquery-public-data.covid19_usafacts.confirmed_cases`        AS cc
      ON LPAD(c2020.geo_id, 5, '0') = cc.county_fips_code
JOIN  `bigquery-public-data.covid19_usafacts.deaths`                 AS cd
      ON cc.county_fips_code = cd.county_fips_code
WHERE c2020.total_pop > 50000       -- restrict to counties with population over 50 k
  AND cc._2020_08_27 IS NOT NULL    -- ensure case data present
  AND cc._2020_08_27 > 0            -- avoid divide-by-zero
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;