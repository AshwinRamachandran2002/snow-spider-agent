-- California census tract with the largest median-income increase between 2015 and 2018
WITH inc AS (
  SELECT
    geo_id,
    CAST(REGEXP_EXTRACT(_TABLE_SUFFIX, r'(\d{4})') AS INT64) AS yr,
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_*`
  WHERE _TABLE_SUFFIX IN ('2015_5yr','2018_5yr')   -- only the two required tables
    AND geo_id LIKE '06%'                          -- California (state FIPS 06)
    AND median_income IS NOT NULL
),
pivot AS (
  SELECT
    geo_id,
    MAX(IF(yr = 2015, median_income, NULL)) AS income_2015,
    MAX(IF(yr = 2018, median_income, NULL)) AS income_2018
  FROM inc
  GROUP BY geo_id
  HAVING income_2015 IS NOT NULL
     AND income_2018 IS NOT NULL
)
SELECT
  geo_id AS tract_code
FROM pivot
ORDER BY (income_2018 - income_2015) DESC
LIMIT 1;