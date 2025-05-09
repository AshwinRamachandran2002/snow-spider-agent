SELECT
  t15.geo_id AS tract_code
FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS t15
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t18
  ON t15.geo_id = t18.geo_id
WHERE t15.geo_id LIKE '06%'            -- California tracts (FIPS 06)
  AND t18.do_date = '2014-01-01'       -- 2014‑2018 ACS 5‑year release
ORDER BY (t18.median_income - t15.median_income) DESC
LIMIT 1;