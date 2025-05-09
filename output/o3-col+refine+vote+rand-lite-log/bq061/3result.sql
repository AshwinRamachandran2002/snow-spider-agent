-- California census tract with the largest jump in median income from 2015 to 2018
WITH incomes AS (
  SELECT
    geo_id,
    CASE _TABLE_SUFFIX
      WHEN '2015_5yr' THEN 2015
      WHEN '2018_5yr' THEN 2018
    END AS yr,
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_*`
  WHERE _TABLE_SUFFIX IN ('2015_5yr', '2018_5yr')   -- only 2015 & 2018 releases
    AND geo_id LIKE '06%'                           -- California tracts
),
pivot AS (
  SELECT
    geo_id,
    MAX(IF(yr = 2015, median_income, NULL)) AS income_2015,
    MAX(IF(yr = 2018, median_income, NULL)) AS income_2018
  FROM incomes
  GROUP BY geo_id
),
changes AS (
  SELECT
    geo_id,
    income_2018 - income_2015 AS income_change
  FROM pivot
  WHERE income_2015 IS NOT NULL
    AND income_2018 IS NOT NULL
)
SELECT geo_id
FROM changes
ORDER BY income_change DESC
LIMIT 1;