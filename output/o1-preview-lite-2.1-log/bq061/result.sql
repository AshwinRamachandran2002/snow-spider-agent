SELECT
  ca.tract_ce AS tract_code,
  ROUND(acs2015.median_income, 4) AS median_income_2015,
  ROUND(acs2018.median_income, 4) AS median_income_2018,
  ROUND((acs2018.median_income - acs2015.median_income), 4) AS income_difference
FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS acs2015
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS acs2018
  ON acs2015.geo_id = acs2018.geo_id
JOIN `bigquery-public-data.geo_census_tracts.census_tracts_california` AS ca
  ON acs2015.geo_id = ca.geo_id
WHERE acs2015.median_income IS NOT NULL
  AND acs2018.median_income IS NOT NULL
ORDER BY income_difference DESC
LIMIT 1;