/*  Annual % share of the 2008 TOP‑5 minor crime categories,
    rounded to 2 dp, one row per year                                 */

WITH top5 AS (               -- the 5 most‑frequent minor categories in 2008
  SELECT minor_category
  FROM  `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
yearly_totals AS (           -- total crimes per year (all categories)
  SELECT year,
         SUM(value) AS total_crimes
  FROM   `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
yearly_cat_totals AS (       -- crimes per year for just the TOP‑5 categories
  SELECT c.year,
         c.minor_category,
         SUM(c.value) AS cat_crimes
  FROM   `bigquery-public-data.london_crime.crime_by_lsoa` AS c
  JOIN   top5 USING (minor_category)
  GROUP  BY c.year, c.minor_category
),
yearly_shares AS (           -- convert to % share of that year’s total crime
  SELECT yct.year,
         yct.minor_category,
         100 * yct.cat_crimes / yt.total_crimes AS pct_share
  FROM   yearly_cat_totals AS yct
  JOIN   yearly_totals      AS yt
    USING (year)
)
SELECT
  year,
  ROUND(MAX(CASE WHEN minor_category = 'Other Theft'              THEN pct_share END), 2) AS other_theft_pct,
  ROUND(MAX(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN pct_share END), 2) AS theft_from_motor_vehicle_pct,
  ROUND(MAX(CASE WHEN minor_category = 'Possession Of Drugs'      THEN pct_share END), 2) AS possession_of_drugs_pct,
  ROUND(MAX(CASE WHEN minor_category = 'Burglary in a Dwelling'   THEN pct_share END), 2) AS burglary_in_a_dwelling_pct,
  ROUND(MAX(CASE WHEN minor_category = 'Assault with Injury'      THEN pct_share END), 2) AS assault_with_injury_pct
FROM   yearly_shares
GROUP  BY year
ORDER  BY year;