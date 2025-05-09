/* Annual % share of each 2008 TOP-5 minor crime category in total London crimes */
WITH top5_2008 AS (          -- fetch the five biggest minor categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
ranked AS (                  -- give them a stable 1-5 ordering
  SELECT
    minor_category,
    ROW_NUMBER() OVER (ORDER BY SUM(value) DESC) AS rn
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
labels AS (                  -- turn rows into one row of labels
  SELECT
    MAX(IF(rn = 1, minor_category, NULL)) AS cat1,
    MAX(IF(rn = 2, minor_category, NULL)) AS cat2,
    MAX(IF(rn = 3, minor_category, NULL)) AS cat3,
    MAX(IF(rn = 4, minor_category, NULL)) AS cat4,
    MAX(IF(rn = 5, minor_category, NULL)) AS cat5
  FROM ranked
)
SELECT
  c.year,
  ROUND(SAFE_DIVIDE(SUM(IF(c.minor_category = l.cat1, c.value, 0)), SUM(c.value))*100, 2) AS cat1_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(c.minor_category = l.cat2, c.value, 0)), SUM(c.value))*100, 2) AS cat2_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(c.minor_category = l.cat3, c.value, 0)), SUM(c.value))*100, 2) AS cat3_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(c.minor_category = l.cat4, c.value, 0)), SUM(c.value))*100, 2) AS cat4_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(c.minor_category = l.cat5, c.value, 0)), SUM(c.value))*100, 2) AS cat5_pct
FROM `bigquery-public-data.london_crime.crime_by_lsoa` AS c
CROSS JOIN labels AS l        -- gives us the category names for the IF() tests
GROUP BY c.year, l.cat1, l.cat2, l.cat3, l.cat4, l.cat5
ORDER BY c.year;