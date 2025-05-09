WITH top5 AS (
  /* top‑5 minor crime categories in 2008 */
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
year_totals AS (
  /* total crimes per year (all categories) */
  SELECT year, SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
cat_year AS (
  /* yearly totals for each of those top‑5 categories */
  SELECT year,
         minor_category,
         SUM(value) AS cat_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5)
  GROUP BY year, minor_category
),
pct AS (
  /* percentage share of each category in the yearly total */
  SELECT cy.year,
         cy.minor_category,
         ROUND(100 * cy.cat_crimes / yt.total_crimes, 2) AS pct_share
  FROM cat_year cy
  JOIN year_totals yt
  ON cy.year = yt.year
)
SELECT
  year,
  MAX(CASE WHEN minor_category = 'Other Theft'              THEN pct_share END) AS `Other Theft`,
  MAX(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN pct_share END) AS `Theft From Motor Vehicle`,
  MAX(CASE WHEN minor_category = 'Possession Of Drugs'      THEN pct_share END) AS `Possession Of Drugs`,
  MAX(CASE WHEN minor_category = 'Burglary in a Dwelling'   THEN pct_share END) AS `Burglary in a Dwelling`,
  MAX(CASE WHEN minor_category = 'Assault with Injury'      THEN pct_share END) AS `Assault with Injury`
FROM pct
GROUP BY year
ORDER BY year;