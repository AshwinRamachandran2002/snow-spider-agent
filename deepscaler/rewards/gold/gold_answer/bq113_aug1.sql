-- Task: List all counties in Utah with their average construction employment in 2018, calculated by averaging the employment levels during the third month of each quarter in that year.
SELECT c.county_name AS County,
       avg2018.avg_employment_2018
FROM (
  SELECT area_fips, AVG(month3_emplvl_23_construction) AS avg_employment_2018
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX LIKE '2018_%'
  GROUP BY area_fips
) AS avg2018
JOIN `bigquery-public-data.geo_us_boundaries.counties` AS c
ON avg2018.area_fips = c.county_fips_code
WHERE c.state_fips_code = '49'
ORDER BY avg2018.avg_employment_2018 DESC
LIMIT 100;