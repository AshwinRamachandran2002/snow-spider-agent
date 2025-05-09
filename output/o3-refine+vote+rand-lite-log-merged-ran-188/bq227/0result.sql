WITH top5_2008 AS (          -- find the five most‑common minor crime categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
year_totals AS (             -- total number of crimes each year (all categories)
  SELECT year,
         SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
year_cat_totals AS (         -- yearly totals for the 2008 top‑5 categories
  SELECT year,
         minor_category,
         SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5_2008)
  GROUP BY year, minor_category
),
shares AS (                  -- percentage share of each of the five categories
  SELECT
    yct.year,
    yct.minor_category,
    ROUND(100 * yct.cat_crimes / yt.total_crimes , 2) AS pct_share
  FROM year_cat_totals yct
  JOIN year_totals yt
  USING (year)
)
SELECT
  year,
  STRING_AGG(
      FORMAT('%s: %.2f%%', minor_category, pct_share)
      ORDER BY pct_share DESC
  ) AS top_5_category_shares
FROM shares
GROUP BY year
ORDER BY year;