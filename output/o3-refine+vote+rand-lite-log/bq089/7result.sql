-- number of COVID‑19 vaccine sites per 1,000 residents for every California county
WITH pop AS (
  SELECT
    geo_id                                 AS county_fips,
    CAST(total_pop AS FLOAT64)             AS total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  -- state FIPS “06” → California
  WHERE SUBSTR(geo_id, 1, 2) = '06'
),
sites AS (
  SELECT
    facility_sub_region_2_code AS county_fips,
    COUNT(DISTINCT facility_place_id)      AS vaccine_sites
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_country_region_code = 'US'
    AND facility_sub_region_1 = 'California'
  GROUP BY county_fips
)
SELECT
  p.county_fips,
  p.total_pop,
  s.vaccine_sites,
  ROUND(SAFE_DIVIDE(s.vaccine_sites, p.total_pop) * 1000, 4) AS sites_per_1000_pop
FROM pop AS p
LEFT JOIN sites AS s
USING (county_fips)
ORDER BY county_fips;