SELECT
  s.county_name                               AS county,
  s.state,
  c.median_age,
  c.total_pop,
  ROUND(s.confirmed_cases / c.total_pop * 100000, 1) AS cases_per_100k,
  ROUND(s.deaths         / c.total_pop * 100000, 1) AS deaths_per_100k,
  ROUND(s.deaths / s.confirmed_cases * 100, 2)      AS case_fatality_rate_pct
FROM `bigquery-public-data.covid19_usafacts.summary`                  AS s
JOIN `bigquery-public-data.census_bureau_acs.county_2020_5yr`         AS c
  ON LPAD(c.geo_id, 5, '0') = s.county_fips_code      -- align FIPS codes
WHERE s.date = '2020-08-27'          -- target date
  AND c.total_pop > 50000            -- counties with population > 50k
  AND s.county_fips_code != '00000'  -- exclude statewide aggregates
  AND s.confirmed_cases > 0          -- avoid division by zero
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;