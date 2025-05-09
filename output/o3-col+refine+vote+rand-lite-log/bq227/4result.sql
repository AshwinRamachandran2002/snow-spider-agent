WITH top5_2008 AS (                 -- 1. The five most frequent minor categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
top5_per_year AS (                  -- 2. Yearly totals for just those five categories
  SELECT
    year,
    SUM(value) AS top5_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5_2008)
  GROUP BY year
),
all_crimes_per_year AS (            -- 3. Yearly totals for ALL crimes
  SELECT
    year,
    SUM(value) AS all_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
)
-- 4. Combine and calculate the percentage share, rounded to two decimals
SELECT
  a.year,
  ROUND(t.top5_crimes * 100.0 / a.all_crimes, 2) AS pct_share_top5_2008
FROM all_crimes_per_year AS a
JOIN top5_per_year       AS t
ON a.year = t.year
ORDER BY a.year;