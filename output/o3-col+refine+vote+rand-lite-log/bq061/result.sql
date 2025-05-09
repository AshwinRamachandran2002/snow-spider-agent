WITH ca_2015 AS (
  SELECT
    geo_id,
    median_income AS income_2015
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr`
  WHERE SUBSTR(geo_id, 1, 2) = '06'          -- 06 = California
    AND median_income IS NOT NULL
),
ca_2018 AS (
  SELECT
    geo_id,
    median_income AS income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE SUBSTR(geo_id, 1, 2) = '06'
    AND median_income IS NOT NULL
),
income_change AS (
  SELECT
    c18.geo_id,
    c18.income_2018 - c15.income_2015 AS delta_income
  FROM ca_2015 c15
  JOIN ca_2018 c18
    USING (geo_id)
)
SELECT
  geo_id AS tract_code
FROM income_change
ORDER BY delta_income DESC
LIMIT 1;