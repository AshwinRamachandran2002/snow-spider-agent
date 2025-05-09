/*  Kings County (FIPS 36047) census tracts that
    • rank in the top-20 (within Kings County) for percentage population growth (2011→2018)
    • rank in the top-20 (within Kings County) for absolute median-income growth (2011→2018)
    • had >1,000 residents in both years
*/

WITH kings_tracts AS (     -- 2011 vs 2018 comparison limited to Kings County
  SELECT
    t11.geo_id,
    t11.total_pop                         AS pop_2011,
    t18.total_pop                         AS pop_2018,
    t11.median_income                     AS inc_2011,
    t18.median_income                     AS inc_2018,
    SAFE_DIVIDE(t18.total_pop - t11.total_pop,
                t11.total_pop)            AS pct_pop_growth,
    (t18.median_income - t11.median_income) AS abs_inc_growth
  FROM  `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` t11
  JOIN  `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` t18
  USING (geo_id)
  WHERE geo_id LIKE '36047%'          -- Kings County tracts only
    AND t11.total_pop  > 1000         -- ≥1,000 residents in 2011
    AND t18.total_pop  > 1000         -- ≥1,000 residents in 2018
    AND t11.median_income IS NOT NULL
    AND t18.median_income IS NOT NULL
),

ranked AS (                -- rank within Kings County
  SELECT
    k.*,
    DENSE_RANK() OVER (ORDER BY pct_pop_growth DESC) AS pop_rank,
    DENSE_RANK() OVER (ORDER BY abs_inc_growth DESC) AS inc_rank
  FROM kings_tracts k
)

SELECT
  geo_id,
  pop_2011,
  pop_2018,
  ROUND(pct_pop_growth, 4) AS pct_pop_growth,
  inc_2011,
  inc_2018,
  abs_inc_growth
FROM  ranked
WHERE pop_rank <= 20        -- top 20 in % population growth (Kings County)
  AND inc_rank <= 20        -- top 20 in $ income growth    (Kings County)
ORDER BY geo_id;