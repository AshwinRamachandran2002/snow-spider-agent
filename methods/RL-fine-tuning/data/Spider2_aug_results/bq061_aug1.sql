-- Task: For census tracts in California, compute the difference in median income between 2015 and 2018. Limit the results to the first 100 entries.

SELECT
  acs_diff.geo_id,
  acs_diff.median_income_diff
FROM (
  SELECT
    a18.geo_id,
    (a18.median_income - a15.median_income) AS median_income_diff
  FROM
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` a18
  JOIN
    `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` a15
  ON
    a18.geo_id = a15.geo_id
) acs_diff
WHERE
  acs_diff.geo_id IN (
    SELECT
      geo_id
    FROM
      `bigquery-public-data.geo_census_tracts.census_tracts_california`
  )
  AND acs_diff.median_income_diff IS NOT NULL
LIMIT 100;