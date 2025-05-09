-- California census tract with the greatest rise in median income
-- between the 2015- and 2018-release ACS 5-year tables
SELECT
  t18.geo_id AS tract_code
FROM
  `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS t15
JOIN
  `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t18
USING (geo_id)
WHERE
  geo_id LIKE '06%'                -- California tracts
  AND t15.median_income IS NOT NULL
  AND t18.median_income IS NOT NULL
ORDER BY
  (t18.median_income - t15.median_income) DESC
LIMIT 1;