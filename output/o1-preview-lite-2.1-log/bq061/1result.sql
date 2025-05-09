SELECT t2015.geo_id
FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS t2015
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t2018
  ON t2015.geo_id = t2018.geo_id
JOIN `bigquery-public-data.geo_census_tracts.census_tracts_california` AS ca
  ON t2015.geo_id = ca.geo_id
WHERE t2015.median_income IS NOT NULL
  AND t2018.median_income IS NOT NULL
ORDER BY (t2018.median_income - t2015.median_income) DESC
LIMIT 1;