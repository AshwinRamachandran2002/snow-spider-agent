/*  Annual percentage shares (rounded to 2 dp) of the five
    most common 2008 minor-crime categories in London’s
    total crime figures – one row per year                       */

WITH
/* 1. Identify the TOP-5 minor-crime categories for 2008 */
top5 AS (
  SELECT ARRAY_AGG(minor_category ORDER BY tot DESC LIMIT 5) AS cats
  FROM (
    SELECT minor_category, SUM(value) AS tot
    FROM `bigquery-public-data.london_crime.crime_by_lsoa`
    WHERE year = 2008
    GROUP BY minor_category
  )
),

/* 2. Yearly grand totals for all crime */
year_totals AS (
  SELECT year, SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),

/* 3. Yearly totals for every minor category
       (will be filtered to TOP-5 later)                      */
cat_year AS (
  SELECT year,
         minor_category,
         SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year, minor_category
)

/* 4. Assemble final percentages – one column per rank-order
       category (pct_cat1 ... pct_cat5)                       */
SELECT
  y.year,
  ROUND(100 * SUM(IF(c.minor_category = cats[OFFSET(0)], c.cat_crimes, 0)) / y.total_crimes, 2) AS pct_cat1,
  ROUND(100 * SUM(IF(c.minor_category = cats[OFFSET(1)], c.cat_crimes, 0)) / y.total_crimes, 2) AS pct_cat2,
  ROUND(100 * SUM(IF(c.minor_category = cats[OFFSET(2)], c.cat_crimes, 0)) / y.total_crimes, 2) AS pct_cat3,
  ROUND(100 * SUM(IF(c.minor_category = cats[OFFSET(3)], c.cat_crimes, 0)) / y.total_crimes, 2) AS pct_cat4,
  ROUND(100 * SUM(IF(c.minor_category = cats[OFFSET(4)], c.cat_crimes, 0)) / y.total_crimes, 2) AS pct_cat5
FROM year_totals   AS y
JOIN cat_year      AS c   USING (year),
     top5                -- brings ARRAY<STRING> cats
WHERE c.minor_category IN UNNEST(cats)
GROUP BY y.year, y.total_crimes, cats
ORDER BY y.year;