/*  Census tracts in Kings County (FIPS 36047) that
    • rank in the top-20 for % population growth (2011→2018),
    • rank in the top-20 for $ median-income growth (2011→2018),
    • had >1 000 residents in both years. */

WITH base AS (
  SELECT
    t11.geo_id,
    t11.total_pop        AS pop_2011,
    t18.total_pop        AS pop_2018,
    SAFE_DIVIDE(t18.total_pop - t11.total_pop, t11.total_pop) AS pct_pop_change,
    t11.median_income    AS mi_2011,
    t18.median_income    AS mi_2018,
    (t18.median_income - t11.median_income)                  AS income_change
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` AS t11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t18
    ON t18.geo_id = t11.geo_id
  WHERE t11.geo_id LIKE '36047%'          -- Kings County
    AND t11.total_pop  > 1000
    AND t18.total_pop  > 1000
    AND t11.median_income > 0
    AND t18.median_income > 0
),
pop_ranked AS (
  SELECT
    base.*,
    RANK() OVER (ORDER BY pct_pop_change DESC) AS pop_rank
  FROM base
),
inc_ranked AS (
  SELECT
    geo_id,
    RANK() OVER (ORDER BY income_change DESC) AS inc_rank
  FROM base
)

SELECT
  p.geo_id,
  p.pop_2011,
  p.pop_2018,
  ROUND(p.pct_pop_change * 100, 2) AS pct_pop_change,
  p.mi_2011  AS median_income_2011,
  p.mi_2018  AS median_income_2018,
  p.income_change
FROM pop_ranked AS p
JOIN inc_ranked AS i
  ON i.geo_id = p.geo_id
WHERE p.pop_rank <= 20
  AND i.inc_rank <= 20
ORDER BY pct_pop_change DESC, income_change DESC;