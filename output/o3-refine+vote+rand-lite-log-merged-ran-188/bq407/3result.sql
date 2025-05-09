-- Top three U.S. counties (population > 50k) with the highest
-- COVID-19 case-fatality rates on 27-Aug-2020
WITH joined AS (
  SELECT
    TRIM(c.county_name)                     AS county,
    c.state                                 AS state,
    a.median_age                            AS median_age,
    a.total_pop                             AS total_pop,
    c._2020_08_27                           AS cases,
    d._2020_08_27                           AS deaths
  FROM `bigquery-public-data.covid19_usafacts.confirmed_cases` AS c
  JOIN `bigquery-public-data.covid19_usafacts.deaths`          AS d
        ON d.county_fips_code = c.county_fips_code
  JOIN `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS a
        ON LPAD(a.geo_id, 5, '0') = c.county_fips_code
  WHERE a.total_pop  > 50000          -- population threshold
    AND c._2020_08_27 > 0            -- must have at least one case
)
SELECT
  county,
  state,
  median_age,
  total_pop,
  ROUND(cases  / total_pop * 1e5, 1)   AS cases_per_100k,
  ROUND(deaths / total_pop * 1e5, 1)   AS deaths_per_100k,
  ROUND(deaths / cases * 100, 2)       AS case_fatality_rate_pct
FROM joined
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;