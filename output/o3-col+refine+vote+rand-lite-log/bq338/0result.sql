/* 36047 census-tracts that are simultaneously
   • top-20 in % population growth (2011→2018) and
   • top-20 in absolute $ increase in median income,
   while having >1 000 residents in both years                                     */

WITH joined AS (       -- side-by-side 2011 vs 2018 values
  SELECT
    t11.geo_id,
    t11.total_pop        AS pop_2011,
    t18.total_pop        AS pop_2018,
    SAFE_DIVIDE(t18.total_pop - t11.total_pop,
                t11.total_pop)                 AS pct_pop_inc,
    t11.median_income    AS income_2011,
    t18.median_income    AS income_2018,
    (t18.median_income   - t11.median_income)  AS income_diff
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` t11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` t18
    USING (geo_id)
  WHERE t11.geo_id LIKE '36047%'          -- Kings County (Brooklyn) tracts
    AND t11.total_pop > 1000
    AND t18.total_pop > 1000
),

ranked AS (            -- rank by the two growth metrics
  SELECT *,
         DENSE_RANK() OVER (ORDER BY pct_pop_inc DESC)  AS pop_rank,
         DENSE_RANK() OVER (ORDER BY income_diff DESC)  AS inc_rank
  FROM joined
)

SELECT
  geo_id,
  pop_2011,
  pop_2018,
  pct_pop_inc,
  income_2011,
  income_2018,
  income_diff
FROM ranked
WHERE pop_rank <= 20          -- top-20 population growth %
  AND inc_rank <= 20          -- top-20 income $ growth
ORDER BY pop_rank, inc_rank;