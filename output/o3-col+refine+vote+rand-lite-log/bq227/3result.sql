/* Annual percentage shares (rounded to 2 dp) of the 2008 TOP-5 minor crime
   categories, returned as one row per year with an ordered array of
   {minor_category, pct_share} pairs. */
WITH top5_2008 AS (               -- 1. TOP-5 minor categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
year_totals AS (                  -- 2. Total crimes per year
  SELECT year, SUM(value) AS total_year
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
year_cat_totals AS (              -- 3. Yearly totals for the TOP-5 categories
  SELECT
    c.year,
    c.minor_category,
    SUM(c.value) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa` AS c
  JOIN top5_2008 USING (minor_category)
  GROUP BY c.year, c.minor_category
),
pct_shares AS (                   -- 4. Convert to percentages (2 dp)
  SELECT
    yct.year,
    yct.minor_category,
    ROUND(100 * yct.cat_total / yt.total_year, 2) AS pct_share
  FROM year_cat_totals AS yct
  JOIN year_totals AS yt
    ON yt.year = yct.year
)
SELECT
  year,
  ARRAY_AGG(
    STRUCT(minor_category, pct_share)
    ORDER BY pct_share DESC
  ) AS top5_minor_category_percentages
FROM pct_shares
GROUP BY year
ORDER BY year;