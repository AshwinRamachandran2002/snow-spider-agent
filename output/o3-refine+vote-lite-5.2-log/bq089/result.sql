-- Vaccine sites per 1,000 residents for each California county
WITH population AS (
  SELECT
    geo_id                         AS county_fips,
    CAST(total_pop AS FLOAT64)     AS total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE geo_id LIKE '06%'                       -- California (FIPS state code 06)
        AND total_pop IS NOT NULL
),
vaccine_sites AS (
  SELECT
    facility_sub_region_2_code     AS county_fips,
    COUNT(DISTINCT facility_place_id) AS site_count
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_country_region_code = 'US'
        AND facility_sub_region_1_code = 'US-CA' -- California
  GROUP BY county_fips
)
SELECT
  p.county_fips,
  p.total_pop,
  IFNULL(v.site_count, 0)                           AS site_count,
  IFNULL(v.site_count, 0) * 1000 / p.total_pop      AS sites_per_1000_pop
FROM population p
LEFT JOIN vaccine_sites v
  USING (county_fips)
ORDER BY sites_per_1000_pop DESC, county_fips;