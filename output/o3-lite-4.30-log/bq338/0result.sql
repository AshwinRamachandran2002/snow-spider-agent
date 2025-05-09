SELECT
  geo_id AS census_tract
FROM (
  SELECT
    p11.geo_id,
    SAFE_DIVIDE(p18.total_pop - p11.total_pop, p11.total_pop) AS pct_pop_change,
    p18.median_income - p11.median_income                     AS income_change,
    RANK() OVER (ORDER BY SAFE_DIVIDE(p18.total_pop - p11.total_pop, p11.total_pop) DESC) AS pop_rank,
    RANK() OVER (ORDER BY (p18.median_income - p11.median_income) DESC)                  AS income_rank
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` p11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` p18
    USING (geo_id)
  WHERE p11.geo_id LIKE '36047%'
    AND p11.total_pop > 1000
    AND p18.total_pop > 1000
)
WHERE pop_rank  <= 20
  AND income_rank <= 20
ORDER BY pop_rank, income_rank, geo_id;