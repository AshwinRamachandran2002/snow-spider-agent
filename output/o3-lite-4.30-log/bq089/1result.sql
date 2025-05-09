WITH pop AS (
  SELECT
    geo_id,
    total_pop
  FROM (
    SELECT
      geo_id,
      total_pop,
      ROW_NUMBER() OVER (PARTITION BY geo_id ORDER BY do_date DESC) AS rn
    FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
    WHERE SUBSTR(geo_id, 1, 2) = '06'          -- California state FIPS
  )
  WHERE rn = 1
),
sites AS (
  SELECT
    facility_sub_region_2_code AS geo_id,
    ANY_VALUE(facility_sub_region_2) AS county_name,
    COUNT(DISTINCT facility_place_id) AS vaccine_sites
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_country_region_code = 'US'
    AND facility_sub_region_1 = 'California'
  GROUP BY geo_id
)
SELECT
  COALESCE(s.county_name, 'Unknown County') AS county,
  ROUND(IFNULL(s.vaccine_sites, 0) * 1000 / p.total_pop, 4) AS sites_per_1000
FROM pop p
LEFT JOIN sites s USING (geo_id)
ORDER BY county;