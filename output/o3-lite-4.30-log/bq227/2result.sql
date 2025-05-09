WITH top5 AS (                       -- top‑5 minor categories in 2008
  SELECT minor_category
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE year = 2008
  GROUP BY minor_category
  ORDER BY SUM(value) DESC
  LIMIT 5
),
cat_year AS (                        -- yearly totals for those categories
  SELECT
    year,
    minor_category,
    SUM(value) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (SELECT minor_category FROM top5)
  GROUP BY year, minor_category
),
year_tot AS (                        -- yearly totals for all crimes
  SELECT
    year,
    SUM(value) AS grand_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
pct AS (                             -- compute percentage share
  SELECT
    cy.year,
    cy.minor_category,
    ROUND(100 * cy.cat_total / yt.grand_total, 2) AS pct_share
  FROM cat_year AS cy
  JOIN year_tot AS yt USING (year)
)
SELECT                                -- pivot to one row per year
  year,
  MAX(IF(minor_category = 'Other Theft',               pct_share, NULL)) AS `Other Theft`,
  MAX(IF(minor_category = 'Theft From Motor Vehicle',  pct_share, NULL)) AS `Theft From Motor Vehicle`,
  MAX(IF(minor_category = 'Possession Of Drugs',       pct_share, NULL)) AS `Possession Of Drugs`,
  MAX(IF(minor_category = 'Burglary in a Dwelling',    pct_share, NULL)) AS `Burglary in a Dwelling`,
  MAX(IF(minor_category = 'Assault with Injury',       pct_share, NULL)) AS `Assault with Injury`
FROM pct
GROUP BY year
ORDER BY year;