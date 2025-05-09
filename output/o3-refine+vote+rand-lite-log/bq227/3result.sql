-- 1) Pick the five minor‑crime categories that occur most often in 2008
WITH top5_2008 AS (
  SELECT
    minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),

-- 2) Yearly totals for the whole of London
year_totals AS (
  SELECT
    year,
    SUM(value) AS year_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),

-- 3) Yearly totals for each of those five categories
year_cat_totals AS (
  SELECT
    c.year,
    c.minor_category,
    SUM(c.value) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa` AS c
  JOIN top5_2008 AS t
  USING (minor_category)
  GROUP BY c.year, c.minor_category
),

-- 4) Combine & turn counts into percentage shares (rounded to 2 dp)
shares AS (
  SELECT
    yct.year,
    yct.minor_category,
    ROUND(100 * yct.cat_total / yt.year_total, 2) AS pct_share
  FROM year_cat_totals AS yct
  JOIN year_totals     AS yt
  USING (year)
)

-- 5) One row per year with an array listing the five shares
SELECT
  year,
  ARRAY_AGG(
      STRUCT(minor_category, pct_share)
      ORDER BY pct_share DESC
  ) AS top5_minor_category_percentage_shares
FROM shares
GROUP BY year
ORDER BY year;