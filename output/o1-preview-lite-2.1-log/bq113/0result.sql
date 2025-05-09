SELECT c.county_name AS County,
       ROUND(((avg2018.avg_employment_2018 - avg2000.avg_employment_2000) /
       NULLIF(avg2000.avg_employment_2000, 0)) * 100, 4) AS Percentage_Increase
FROM (
  SELECT area_fips, AVG(month3_emplvl_23_construction) AS avg_employment_2000
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX LIKE '2000_%'
  GROUP BY area_fips
) AS avg2000
JOIN (
  SELECT area_fips, AVG(month3_emplvl_23_construction) AS avg_employment_2018
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX LIKE '2018_%'
  GROUP BY area_fips
) AS avg2018
ON avg2000.area_fips = avg2018.area_fips
JOIN `bigquery-public-data.geo_us_boundaries.counties` AS c
ON avg2000.area_fips = c.county_fips_code
WHERE c.state_fips_code = '49'
ORDER BY Percentage_Increase DESC
LIMIT 1;