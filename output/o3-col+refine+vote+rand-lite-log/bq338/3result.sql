/*  Census tracts in New-York County (FIPS 36047) that:
    1. Had >1,000 residents in both 2011 & 2018
    2. Rank in the TOP-20 for % population growth (2011-→2018)
    3. Rank in the TOP-20 for absolute median-income increase (2011-→2018)
*/
WITH base AS (
  SELECT
    t11.geo_id,
    t11.total_pop        AS pop_2011,
    s18.pop_2018,
    t11.median_income    AS income_2011,
    s18.income_2018
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` AS t11
  JOIN (
        /* collapse 2018 5-yr table to one row per tract */
        SELECT
          geo_id,
          ANY_VALUE(total_pop)     AS pop_2018,
          ANY_VALUE(median_income) AS income_2018
        FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
        WHERE geo_id LIKE '36047%'               -- New-York County
        GROUP BY geo_id
       ) AS s18
  USING (geo_id)
  WHERE t11.geo_id  LIKE '36047%'                -- New-York County
    AND t11.total_pop  > 1000                    -- pop threshold 2011
    AND s18.pop_2018   > 1000                    -- pop threshold 2018
),
top_pop_growth AS (
  SELECT geo_id
  FROM   base
  ORDER  BY (pop_2018 - pop_2011) / pop_2011 DESC
  LIMIT  20
),
top_income_gain AS (
  SELECT geo_id
  FROM   base
  ORDER  BY (income_2018 - income_2011) DESC
  LIMIT  20
)
SELECT
  b.geo_id,
  b.pop_2011,
  b.pop_2018,
  ROUND(100.0 * (b.pop_2018 - b.pop_2011) / b.pop_2011, 2) AS pct_pop_increase,
  b.income_2011,
  b.income_2018,
  (b.income_2018 - b.income_2011)                           AS abs_income_increase
FROM base AS b
JOIN top_pop_growth  USING (geo_id)
JOIN top_income_gain USING (geo_id)
ORDER BY pct_pop_increase DESC;