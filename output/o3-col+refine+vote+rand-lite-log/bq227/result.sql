/*  Annual percentage share (rounded to two decimals) of the
    five minor-crime categories that were most common in 2008  */

WITH top5 AS (                       -- top-5 minor categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
year_tot AS (                        -- city-wide totals for each year
  SELECT year, SUM(value) AS year_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
cat_tot AS (                         -- yearly totals for each top-5 category
  SELECT year,
         minor_category,
         SUM(value) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5)
  GROUP BY year, minor_category
),
pct AS (                             -- convert to % of that year’s total
  SELECT
    ct.year,
    ct.minor_category,
    ROUND(100 * ct.cat_total / yt.year_total, 2) AS pct_share
  FROM cat_tot ct
  JOIN year_tot yt USING (year)
)
SELECT *
FROM pct
PIVOT (                              -- one row per year, one column per category
  MAX(pct_share) FOR minor_category IN (
    'Other Theft',
    'Theft From Motor Vehicle',
    'Possession Of Drugs',
    'Burglary in a Dwelling',
    'Assault with Injury'
  )
)
ORDER BY year;