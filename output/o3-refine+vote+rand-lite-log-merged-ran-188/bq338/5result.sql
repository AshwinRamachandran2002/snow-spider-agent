/* Census tracts in Kings County (FIPS 36047) that:
   1. Rank in the top-20 for % population growth (2011→2018)
   2. Rank in the top-20 for absolute median-income increase (2011→2018)
   3. Had ≥1,000 residents in both 2011 and 2018                                                   */
WITH
-- Top-20 tracts by percent population growth
pop_growth AS (
  SELECT
    t11.geo_id,
    SAFE_DIVIDE(t18.total_pop - t11.total_pop, t11.total_pop) * 100 AS pct_pop_growth,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(t18.total_pop - t11.total_pop, t11.total_pop) DESC) AS rnk
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` t11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` t18
    USING (geo_id)
  WHERE t11.geo_id LIKE '36047%'                  -- Kings County
    AND t11.total_pop >= 1000
    AND t18.total_pop >= 1000
),
pop_top20 AS (
  SELECT geo_id
  FROM   pop_growth
  WHERE  rnk <= 20
),

-- Top-20 tracts by absolute median-income gain
income_growth AS (
  SELECT
    t11.geo_id,
    (t18.median_income - t11.median_income) AS income_change,
    ROW_NUMBER() OVER (ORDER BY (t18.median_income - t11.median_income) DESC) AS rnk
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` t11
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` t18
    USING (geo_id)
  WHERE t11.geo_id LIKE '36047%'
    AND t11.total_pop >= 1000
    AND t18.total_pop >= 1000
    AND t11.median_income IS NOT NULL
    AND t18.median_income IS NOT NULL
),
income_top20 AS (
  SELECT geo_id
  FROM   income_growth
  WHERE  rnk <= 20
)

-- Intersection of the two top-20 lists
SELECT DISTINCT p.geo_id
FROM   pop_top20   p
JOIN   income_top20 i
  ON   p.geo_id = i.geo_id
ORDER BY geo_id;