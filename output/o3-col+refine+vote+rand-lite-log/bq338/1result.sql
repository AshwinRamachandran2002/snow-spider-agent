/*  Kings County (FIPS 36047) census tracts that
    1) gained ≥1 000 residents in both 2011 & 2018
    2) rank in the TOP-20 for %-population growth, and
    3) rank in the TOP-20 for absolute ↑ in median income
    between the 2011- and 2018-ACS 5-year releases          */

WITH base AS (                       -- 2011 vs 2018 side-by-side
  SELECT
    a.geo_id,
    a.total_pop        AS pop_2011,
    b.total_pop        AS pop_2018,
    a.median_income    AS inc_2011,
    b.median_income    AS inc_2018,
    100 * (b.total_pop - a.total_pop) / a.total_pop              AS pct_pop_change,
    (b.median_income - a.median_income)                          AS inc_change
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` a
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` b
        ON a.geo_id = b.geo_id
  WHERE a.geo_id LIKE '36047%'          -- Kings County tracts
    AND a.total_pop > 1000              -- ≥1 000 residents in 2011
    AND b.total_pop > 1000              -- ≥1 000 residents in 2018
),
pop_ranked AS (                        -- rank by % pop growth
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY pct_pop_change DESC) AS pop_rn
  FROM base
),
inc_ranked AS (                        -- rank by $ income growth
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY inc_change DESC)     AS inc_rn
  FROM pop_ranked
)
SELECT
  geo_id,
  pop_2011,
  pop_2018,
  ROUND(pct_pop_change,2) AS pct_pop_change,
  inc_2011,
  inc_2018,
  inc_change
FROM inc_ranked
WHERE pop_rn <= 20
  AND inc_rn <= 20
ORDER BY geo_id;