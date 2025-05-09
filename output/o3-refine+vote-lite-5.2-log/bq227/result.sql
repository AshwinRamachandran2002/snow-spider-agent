/*  Annual percentage share (rounded to two decimals) of the five
    most‑frequent minor crime categories in 2008, one row per year      */

WITH top_5_2008 AS (        -- 1. find the 5 biggest minor categories in 2008
  SELECT
    minor_category,
    ROW_NUMBER() OVER (ORDER BY SUM(value) DESC) AS rn
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),

overall_year_totals AS (    -- 2. total crime volume each year (all categories)
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),

cat_year_totals AS (        -- 3. yearly totals ONLY for the 5 categories above
  SELECT
    year,
    minor_category,
    SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top_5_2008)
  GROUP BY year, minor_category
),

percentages AS (            -- 4. convert to percentages of that year’s total
  SELECT
    o.year,
    t.rn,                          -- rank 1‑5 from the 2008 ordering
    t.minor_category,
    ROUND(100 * c.cat_crimes / o.total_crimes, 2) AS pct_share
  FROM cat_year_totals  c
  JOIN overall_year_totals o  USING (year)
  JOIN top_5_2008       t  ON c.minor_category = t.minor_category
)

-- 5. pivot so that each year appears once, one column per category rank
SELECT
  year,
  MAX(CASE WHEN rn = 1 THEN pct_share END) AS cat1_pct,
  MAX(CASE WHEN rn = 2 THEN pct_share END) AS cat2_pct,
  MAX(CASE WHEN rn = 3 THEN pct_share END) AS cat3_pct,
  MAX(CASE WHEN rn = 4 THEN pct_share END) AS cat4_pct,
  MAX(CASE WHEN rn = 5 THEN pct_share END) AS cat5_pct
FROM percentages
GROUP BY year
ORDER BY year;