/*  Tracts in Kings County (FIPS 36047) that
    ① rank in the TOP-20 for % population growth (2011→2018),
    ② rank in the TOP-20 for absolute median-income growth (2011→2018),
    ③ had ≥1 000 residents in both years.                                     */

WITH
-- 2011 ACS 5-year numbers
y11 AS (
  SELECT
    geo_id,
    total_pop     AS pop11,
    median_income AS inc11
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr`
  WHERE geo_id LIKE '36047%'                       -- Kings County
),

-- 2018 ACS 5-year numbers (keep latest do_date if duplicates exist)
y18 AS (
  SELECT
    geo_id,
    ARRAY_AGG(STRUCT(do_date,total_pop,median_income)
              ORDER BY do_date DESC)[OFFSET(0)].total_pop      AS pop18,
    ARRAY_AGG(STRUCT(do_date,total_pop,median_income)
              ORDER BY do_date DESC)[OFFSET(0)].median_income  AS inc18
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE geo_id LIKE '36047%'
  GROUP BY geo_id
),

-- Pair the two years and compute changes
paired AS (
  SELECT
    y11.geo_id,
    y11.pop11,
    y18.pop18,
    y11.inc11,
    y18.inc18,
    SAFE_DIVIDE(y18.pop18 - y11.pop11 , y11.pop11) AS pct_pop_change,
    (y18.inc18 - y11.inc11)                        AS abs_inc_change
  FROM y11
  JOIN y18 USING (geo_id)
  WHERE y11.pop11 >= 1000
    AND y18.pop18 >= 1000
    AND y11.inc11 IS NOT NULL
    AND y18.inc18 IS NOT NULL
),

-- Rank by the two growth metrics
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY pct_pop_change DESC) AS r_pop,
    DENSE_RANK() OVER (ORDER BY abs_inc_change DESC) AS r_inc
  FROM paired
)

-- Final list: tracts in BOTH top-20 lists
SELECT
  geo_id,
  pop11,
  pop18,
  ROUND(pct_pop_change * 100, 2) AS pct_population_increase,
  abs_inc_change                 AS median_income_increase
FROM ranked
WHERE r_pop <= 20
  AND r_inc <= 20
ORDER BY pct_population_increase DESC, median_income_increase DESC;