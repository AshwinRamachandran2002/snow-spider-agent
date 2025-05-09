SELECT
    SUBSTR(t2015.geo_id, -11) AS tract_code,
    ROUND(t2015.median_income, 4) AS median_income_2015,
    ROUND(t2018.median_income, 4) AS median_income_2018,
    ROUND(t2018.median_income - t2015.median_income, 4) AS median_income_change
FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` AS t2015
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t2018
  ON t2015.geo_id = t2018.geo_id
WHERE SUBSTR(t2015.geo_id, 10, 2) = '06'  -- California FIPS code
  AND t2015.median_income IS NOT NULL
  AND t2018.median_income IS NOT NULL
ORDER BY median_income_change DESC
LIMIT 1;