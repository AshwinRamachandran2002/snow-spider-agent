SELECT
  t18.geo_id AS tract_code
FROM
  `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t18
JOIN
  `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS t15
ON
  t18.geo_id = t15.geo_id
WHERE
  t18.geo_id LIKE '06%'   -- California tracts
  AND t18.median_income IS NOT NULL
  AND t15.median_income IS NOT NULL
ORDER BY
  (t18.median_income - t15.median_income) DESC
LIMIT 1;