-- Annual percentage shares of the five largest‑volume 2008 minor‑crime categories
WITH top5_2008 AS (   -- 1. find the five busiest minor categories in 2008
  SELECT
    minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
all_years AS (        -- 2. list of all calendar years in the crime table
  SELECT DISTINCT year
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
),
year_totals AS (      -- 3. total crime count per year (all categories)
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
cat_year_counts AS (  -- 4. crime count per (year, top‑5 category) pair
  SELECT
    y.year,
    t.minor_category,
    SUM(IFNULL(c.value,0)) AS category_crimes
  FROM all_years y
  CROSS JOIN top5_2008 t
  LEFT JOIN `bigquery-public-data.london_crime.crime_by_lsoa` c
    ON c.year = y.year
   AND c.minor_category = t.minor_category
  GROUP BY y.year, t.minor_category
),
cat_year_pcts AS (    -- 5. percentage share of each selected category per year
  SELECT
    c.year,
    c.minor_category,
    ROUND(100 * c.category_crimes / t.total_crimes, 2) AS pct_share
  FROM cat_year_counts c
  JOIN year_totals t
    ON c.year = t.year
)
-- 6. present one row per year: array of (minor_category, pct_share) structs
SELECT
  year,
  ARRAY_AGG(STRUCT(minor_category, pct_share)
            ORDER BY minor_category) AS top5_minor_category_pct_share
FROM cat_year_pcts
GROUP BY year
ORDER BY year;