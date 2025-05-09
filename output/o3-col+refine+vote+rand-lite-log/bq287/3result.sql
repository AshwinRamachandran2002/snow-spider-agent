/*  Employment-to-population rate (age 16+) for the Utah ZIP code(s) that have
    the fewest FDIC-insured bank locations                                   */

WITH fdic_counts AS (
  SELECT
    zip_code,
    COUNT(*) AS fdic_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'UT'
  GROUP BY zip_code
),
min_locs AS (
  SELECT MIN(fdic_locations) AS fewest_fdic_locations
  FROM fdic_counts
),
fewest_zip AS (
  SELECT zip_code
  FROM fdic_counts
  JOIN min_locs ON fdic_locations = fewest_fdic_locations
),
acs_rates AS (
  SELECT
    REGEXP_EXTRACT(geo_id, r'(\d{5})$') AS zip_code,
    SAFE_DIVIDE(employed_pop, pop_16_over) * 100.0 AS emp_rate_16plus_2017
  FROM `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr`
)

SELECT
  f.zip_code,
  ROUND(a.emp_rate_16plus_2017, 4) AS emp_rate_16plus_2017
FROM fewest_zip AS f
LEFT JOIN acs_rates AS a USING (zip_code)
ORDER BY f.zip_code;