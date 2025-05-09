WITH income_2015 AS (
  SELECT
    geo_id,
    MAX(median_income) AS income_2015
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr`
  WHERE LEFT(geo_id, 2) = '06'       -- California tracts
    AND median_income IS NOT NULL
  GROUP BY geo_id
),
income_2018 AS (
  SELECT
    geo_id,
    MAX(median_income) AS income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE LEFT(geo_id, 2) = '06'
    AND median_income IS NOT NULL
  GROUP BY geo_id
),
change AS (
  SELECT
    i18.geo_id,
    i18.income_2018 - i15.income_2015 AS income_change
  FROM income_2018 i18
  JOIN income_2015 i15 USING (geo_id)
)
SELECT geo_id
FROM change
ORDER BY income_change DESC
LIMIT 1;