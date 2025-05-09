-- Which California census tract recorded the largest jump in median income
-- between the 2015-ACS 5-year release and the 2018-ACS 5-year release?
WITH inc_2015 AS (
  SELECT
    geo_id,
    MAX(median_income) AS income_2015          -- unique value per tract
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr`
  WHERE geo_id LIKE '06%'                      -- California FIPS prefix
  GROUP BY geo_id
),
inc_2018 AS (
  SELECT
    geo_id,
    MAX(median_income) AS income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE geo_id LIKE '06%'
  GROUP BY geo_id
),
changes AS (
  SELECT
    i18.geo_id      AS tract_code,
    i18.income_2018,
    i15.income_2015,
    i18.income_2018 - i15.income_2015 AS income_change
  FROM inc_2015 i15
  JOIN inc_2018 i18 USING (geo_id)
  WHERE i15.income_2015 IS NOT NULL
    AND i18.income_2018 IS NOT NULL
)
SELECT tract_code
FROM changes
ORDER BY income_change DESC
LIMIT 1;