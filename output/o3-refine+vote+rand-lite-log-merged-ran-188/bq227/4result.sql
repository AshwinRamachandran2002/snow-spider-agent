WITH
/* 1. Top‑5 minor crime categories in 2008 */
top5 AS (
  SELECT
    minor_category,
    DENSE_RANK() OVER (ORDER BY SUM(value) DESC) AS rk
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY rk
  LIMIT 5
),

/* 2. Total number of crimes per year (all categories) */
yearly_totals AS (
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),

/* 3. Yearly totals for each of the top‑5 categories */
top5_yearly AS (
  SELECT
    c.year,
    t.rk,
    SUM(c.value) AS category_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa` AS c
  JOIN top5 AS t
    ON c.minor_category = t.minor_category
  GROUP BY c.year, t.rk
)

/* 4. Pivot the five categories so each year is one row */
SELECT
  yt.year,
  ROUND(100 * MAX(IF(ty.rk = 1, ty.category_crimes, NULL)) / yt.total_crimes, 2) AS top1_share,
  ROUND(100 * MAX(IF(ty.rk = 2, ty.category_crimes, NULL)) / yt.total_crimes, 2) AS top2_share,
  ROUND(100 * MAX(IF(ty.rk = 3, ty.category_crimes, NULL)) / yt.total_crimes, 2) AS top3_share,
  ROUND(100 * MAX(IF(ty.rk = 4, ty.category_crimes, NULL)) / yt.total_crimes, 2) AS top4_share,
  ROUND(100 * MAX(IF(ty.rk = 5, ty.category_crimes, NULL)) / yt.total_crimes, 2) AS top5_share
FROM yearly_totals AS yt
LEFT JOIN top5_yearly AS ty
  ON yt.year = ty.year
GROUP BY yt.year, yt.total_crimes
ORDER BY yt.year;