/* Annual percentage share of the five minor-crime categories
   that were most common in 2008 */
WITH top5 AS (                      -- five biggest 2008 minor-crime categories
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
year_tot AS (                       -- total crimes per year (all categories)
  SELECT year, SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
year_cat_tot AS (                   -- yearly totals for those five categories
  SELECT
    year,
    minor_category,
    SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5)
  GROUP BY year, minor_category
)
SELECT
  yt.year,
  ROUND(100 * SUM(CASE WHEN yct.minor_category = (SELECT minor_category FROM top5 LIMIT 1 OFFSET 0)
                       THEN yct.cat_crimes ELSE 0 END) / MAX(yt.total_crimes), 2) AS top1_pct,
  ROUND(100 * SUM(CASE WHEN yct.minor_category = (SELECT minor_category FROM top5 LIMIT 1 OFFSET 1)
                       THEN yct.cat_crimes ELSE 0 END) / MAX(yt.total_crimes), 2) AS top2_pct,
  ROUND(100 * SUM(CASE WHEN yct.minor_category = (SELECT minor_category FROM top5 LIMIT 1 OFFSET 2)
                       THEN yct.cat_crimes ELSE 0 END) / MAX(yt.total_crimes), 2) AS top3_pct,
  ROUND(100 * SUM(CASE WHEN yct.minor_category = (SELECT minor_category FROM top5 LIMIT 1 OFFSET 3)
                       THEN yct.cat_crimes ELSE 0 END) / MAX(yt.total_crimes), 2) AS top4_pct,
  ROUND(100 * SUM(CASE WHEN yct.minor_category = (SELECT minor_category FROM top5 LIMIT 1 OFFSET 4)
                       THEN yct.cat_crimes ELSE 0 END) / MAX(yt.total_crimes), 2) AS top5_pct
FROM year_cat_tot AS yct
JOIN year_tot AS yt USING (year)
GROUP BY yt.year
ORDER BY yt.year;