WITH base AS (
  SELECT
    t11.geo_id AS census_tract,
    t11.total_pop AS pop_2011,
    t18.total_pop AS pop_2018,
    SAFE_DIVIDE(t18.total_pop - t11.total_pop, t11.total_pop) AS pct_pop_change,
    t18.median_income - t11.median_income AS income_change
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` t11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` t18
    ON t11.geo_id = t18.geo_id
  WHERE LEFT(t11.geo_id, 5) = '36047'
    AND t11.total_pop >= 1000
    AND t18.total_pop >= 1000
),
top_pop AS (
  SELECT census_tract
  FROM base
  ORDER BY pct_pop_change DESC
  LIMIT 20
),
top_income AS (
  SELECT census_tract
  FROM base
  ORDER BY income_change DESC
  LIMIT 20
)
SELECT DISTINCT census_tract
FROM top_pop
JOIN top_income USING (census_tract)
ORDER BY census_tract;