-- Task: Calculate the difference in median income between 2015 and 2018 for each ZIP code. Limit the results to 100 rows.
WITH acs_2018 AS (
  SELECT
    "geo_id",
    "median_income" AS "median_income_2018"
  FROM
    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
),
acs_2015 AS (
  SELECT
    "geo_id",
    "median_income" AS "median_income_2015"
  FROM
    CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
),
acs_diff AS (
  SELECT
    a18."geo_id",
    (a18."median_income_2018" - a15."median_income_2015") AS "median_income_diff"
  FROM
    acs_2018 a18
  JOIN
    acs_2015 a15 ON a18."geo_id" = a15."geo_id"
)
SELECT
  "geo_id",
  "median_income_diff"
FROM
  acs_diff
WHERE
  "median_income_diff" IS NOT NULL
LIMIT 100;