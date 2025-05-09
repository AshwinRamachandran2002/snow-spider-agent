WITH top5 AS (  -- 5 most common minor‑crime categories in 2008
  SELECT
    minor_category,
    ROW_NUMBER() OVER (ORDER BY SUM(value) DESC) AS rn
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
yearly_cat AS (  -- yearly totals for those 5 categories
  SELECT
    c.year,
    c.minor_category,
    SUM(c.value) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa` AS c
  JOIN top5 t
    ON c.minor_category = t.minor_category
  GROUP BY c.year, c.minor_category
),
yearly_tot AS (  -- overall yearly crime totals
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
)
SELECT
  yt.year,
  ROUND(100 * SUM(IF(yc.minor_category = (SELECT minor_category FROM top5 WHERE rn = 1), yc.cat_total, 0)) / yt.total_crimes, 2) AS top1_pct,
  ROUND(100 * SUM(IF(yc.minor_category = (SELECT minor_category FROM top5 WHERE rn = 2), yc.cat_total, 0)) / yt.total_crimes, 2) AS top2_pct,
  ROUND(100 * SUM(IF(yc.minor_category = (SELECT minor_category FROM top5 WHERE rn = 3), yc.cat_total, 0)) / yt.total_crimes, 2) AS top3_pct,
  ROUND(100 * SUM(IF(yc.minor_category = (SELECT minor_category FROM top5 WHERE rn = 4), yc.cat_total, 0)) / yt.total_crimes, 2) AS top4_pct,
  ROUND(100 * SUM(IF(yc.minor_category = (SELECT minor_category FROM top5 WHERE rn = 5), yc.cat_total, 0)) / yt.total_crimes, 2) AS top5_pct
FROM yearly_tot AS yt
LEFT JOIN yearly_cat AS yc
  ON yt.year = yc.year
GROUP BY yt.year, yt.total_crimes
ORDER BY yt.year;