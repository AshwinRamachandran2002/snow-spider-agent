/* Vaccine sites per-1,000 residents for each California county */

WITH county_pop AS (   -- 2018 ACS 5-year population (California only)
  SELECT
    geo_id,
    SAFE_CAST(total_pop AS FLOAT64) AS total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE STARTS_WITH(geo_id, '06')                -- 06 = California
),

county_names AS (      -- Map FIPS → "<County> County"
  SELECT
    geo_id,
    CONCAT(county_name, ' County') AS county_name
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE STARTS_WITH(geo_id, '06')                -- California counties
),

pop_with_name AS (     -- Attach readable county name to population
  SELECT
    n.county_name,
    p.total_pop
  FROM county_pop  AS p
  JOIN county_names AS n
  USING (geo_id)
),

site_counts AS (       -- Distinct vaccination facilities per county
  SELECT
    facility_sub_region_2 AS county_name,
    COUNT(DISTINCT facility_name) AS site_cnt
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1 = 'California'
  GROUP BY county_name
)

SELECT
  p.county_name,
  s.site_cnt,
  p.total_pop,
  ROUND(s.site_cnt * 1000 / p.total_pop, 4) AS sites_per_1000_people
FROM pop_with_name AS p
JOIN site_counts   AS s
USING (county_name)
ORDER BY sites_per_1000_people DESC;