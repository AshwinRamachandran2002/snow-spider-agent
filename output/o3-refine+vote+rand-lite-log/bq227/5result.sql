WITH
-- 1. top‑5 minor crime categories in 2008
top5 AS (
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),

-- 2. total number of crimes each year (all categories)
year_totals AS (
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),

-- 3. annual totals for those top‑5 categories only
cat_year AS (
  SELECT
    year,
    minor_category,
    SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5)
  GROUP BY year, minor_category
)

-- 4. assemble one row per year with the five percentage shares
SELECT
  yt.year,
  ARRAY_AGG(
        STRUCT(
          cy.minor_category AS minor_category,
          ROUND(100 * cy.cat_crimes / yt.total_crimes, 2) AS percentage_share
        )
        ORDER BY cy.cat_crimes DESC
  ) AS top5_percentage_shares
FROM year_totals AS yt
JOIN cat_year   AS cy
  ON yt.year = cy.year
GROUP BY yt.year
ORDER BY yt.year;