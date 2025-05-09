-- Kings-County (FIPS 36047) tracts that are simultaneously
--  • top-20 in % population growth (2011→2018)
--  • top-20 in absolute median-income growth (2011→2018)
--  • have >1 000 residents in both years
WITH joined AS (
  SELECT
    a.geo_id,
    a.total_pop     AS pop_2011,
    b.total_pop     AS pop_2018,
    a.median_income AS inc_2011,
    b.median_income AS inc_2018,
    SAFE_DIVIDE(b.total_pop - a.total_pop, a.total_pop) AS pct_pop_change,
    (b.median_income - a.median_income)                AS abs_inc_change
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` AS a
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS b
    USING (geo_id)
  WHERE LEFT(a.geo_id, 5) = '36047'      -- Kings County
    AND a.total_pop > 1000               -- population threshold, 2011
    AND b.total_pop > 1000               -- population threshold, 2018
),
ranks AS (
  SELECT
    geo_id,
    RANK() OVER (ORDER BY pct_pop_change DESC) AS pop_rank,
    RANK() OVER (ORDER BY abs_inc_change DESC) AS inc_rank
  FROM joined
)
SELECT
  j.geo_id,
  j.pop_2011,
  j.pop_2018,
  j.pct_pop_change,
  j.inc_2011,
  j.inc_2018,
  j.abs_inc_change
FROM joined AS j
JOIN ranks  AS r USING (geo_id)
WHERE r.pop_rank <= 20
  AND r.inc_rank <= 20
ORDER BY r.pop_rank, r.inc_rank;