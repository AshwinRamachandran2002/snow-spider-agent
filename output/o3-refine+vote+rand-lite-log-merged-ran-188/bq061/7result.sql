/* California tract with the largest median-income increase between the
   2015 and 2018 ACS 5-year releases */
WITH inc_2015 AS (
  SELECT
    geo_id,
    median_income AS income_2015
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr`
  WHERE LEFT(geo_id, 2) = '06'          -- California
    AND median_income IS NOT NULL
),
inc_2018 AS (
  SELECT
    geo_id,
    median_income AS income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE LEFT(geo_id, 2) = '06'
    AND median_income IS NOT NULL
)
SELECT
  inc_2018.geo_id
FROM inc_2018
JOIN inc_2015 USING (geo_id)
ORDER BY (inc_2018.income_2018 - inc_2015.income_2015) DESC
LIMIT 1;