WITH joined AS (
  SELECT
    s.county_name AS county,
    s.state,
    acs.median_age,
    acs.total_pop,
    s.confirmed_cases,
    s.deaths
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS acs
  JOIN `bigquery-public-data.covid19_usafacts.summary`           AS s
    ON LPAD(acs.geo_id, 5, '0') = s.county_fips_code
  WHERE s.date = '2020-08-27'
    AND acs.total_pop > 50000
    AND s.confirmed_cases > 0
)
SELECT
  county,
  state,
  median_age,
  total_pop,
  ROUND((confirmed_cases / total_pop) * 100000, 1) AS cases_per_100k,
  ROUND((deaths         / total_pop) * 100000, 1) AS deaths_per_100k,
  ROUND((deaths / confirmed_cases) * 100, 2)      AS case_fatality_rate_pct
FROM joined
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;