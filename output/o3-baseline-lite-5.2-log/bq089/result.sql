/*  Vaccine sites per 1,000 residents by California county
    – population: 2018 ACS 5‑year estimates
    – vaccine sites: distinct facilities in the vaccination‑access dataset      */

WITH vaccine_sites AS (
  SELECT
    facility_sub_region_2_code AS county_fips,            -- 5‑digit county FIPS
    COUNT(DISTINCT facility_place_id)   AS site_count     -- unique locations
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_country_region_code = 'US'
    AND facility_sub_region_1_code      = 'US-CA'         -- California only
  GROUP BY county_fips
),
county_pop AS (
  SELECT
    geo_id                    AS county_fips,             -- 5‑digit county FIPS
    CAST(total_pop AS FLOAT64) AS total_pop                -- 2018 population
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE LEFT(geo_id, 2) = '06'                            -- California counties
)

SELECT
  cp.county_fips,
  vs.site_count,
  cp.total_pop,
  ROUND( vs.site_count / (cp.total_pop / 1000), 4 ) AS sites_per_1000_pop
FROM county_pop cp
LEFT JOIN vaccine_sites vs
USING (county_fips)
ORDER BY sites_per_1000_pop DESC;