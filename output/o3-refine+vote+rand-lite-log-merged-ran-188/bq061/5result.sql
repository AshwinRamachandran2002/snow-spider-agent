-- Census-tract that experienced the greatest median-income jump (2015 → 2018) in California
WITH inc15 AS (
  SELECT
    geo_id,
    median_income AS income_2015
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr`
  WHERE LEFT(geo_id, 2) = '06'       -- California
),
inc18 AS (
  SELECT
    geo_id,
    median_income AS income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE LEFT(geo_id, 2) = '06'
)

SELECT
  inc18.geo_id
FROM inc18
JOIN inc15 USING (geo_id)
ORDER BY (inc18.income_2018 - inc15.income_2015) DESC
LIMIT 1;