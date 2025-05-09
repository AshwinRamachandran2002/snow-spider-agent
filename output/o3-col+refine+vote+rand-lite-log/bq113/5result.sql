-- Which Utah county saw the largest percentage rise in construction employment
-- between 2000 and 2018 (average of the 3rd-month employment in each quarter)?
WITH year2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_construct_2000
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE _TABLE_SUFFIX IN ('1','2','3','4')          -- q1-q4
    AND area_fips LIKE '49%'                        -- Utah state FIPS prefix
  GROUP BY area_fips
),
year2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_construct_2018
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE _TABLE_SUFFIX IN ('1','2','3','4')          -- q1-q4
    AND area_fips LIKE '49%'                        -- Utah counties
  GROUP BY area_fips
)
SELECT
  c.county_name                           AS utah_county,
  ROUND(
    100.0 * (y18.avg_construct_2018 - y00.avg_construct_2000)
    / y00.avg_construct_2000, 2)          AS percentage_increase
FROM year2000 y00
JOIN year2018 y18 USING (area_fips)
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = y00.area_fips
ORDER BY percentage_increase DESC
LIMIT 1;