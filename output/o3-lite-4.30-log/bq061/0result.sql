SELECT
  a.geo_id AS tract_code
FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS a
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS b
  ON a.geo_id = b.geo_id
WHERE a.geo_id LIKE '06%'          -- California tracts
  AND b.do_date = DATE '2014-01-01'
  AND a.median_income IS NOT NULL
  AND b.median_income IS NOT NULL
ORDER BY (b.median_income - a.median_income) DESC, a.geo_id
LIMIT 1;