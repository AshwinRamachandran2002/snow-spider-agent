/*  Annual percentage shares of the 2008 “top–5” minor crime categories
    in London’s total crimes.  One row per year, percentages rounded to 2‑dp. */
WITH top5_2008 AS (               -- 1. find the five most common minor categories in 2008
  SELECT
    minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
shares AS (                       -- 2. work out each chosen category’s yearly share
  SELECT
    year,
    minor_category,
    ROUND(100 * SUM(value) /
          SUM(SUM(value)) OVER (PARTITION BY year) , 2)   AS pct_share
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5_2008)
  GROUP BY year, minor_category
)
-- 3. present every year on a single line
SELECT
  year,
  STRING_AGG(
      CONCAT(minor_category, ': ', FORMAT('%.2f', pct_share)),
      ', ' ORDER BY pct_share DESC
  ) AS top5_percentage_shares
FROM shares
GROUP BY year
ORDER BY year;