WITH top5_2008 AS (      -- 5 most frequent minor categories in 2008
  SELECT 'Other Theft'              AS minor_category UNION ALL
  SELECT 'Theft From Motor Vehicle' UNION ALL
  SELECT 'Possession Of Drugs'      UNION ALL
  SELECT 'Burglary in a Dwelling'   UNION ALL
  SELECT 'Assault with Injury'
),
city_year AS (           -- total crimes per year (all categories)
  SELECT
    `year`,
    SUM(`value`) AS city_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY `year`
),
cat_year AS (            -- yearly totals for the five chosen categories
  SELECT
    `year`,
    `minor_category`,
    SUM(`value`) AS cat_total
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE `minor_category` IN (SELECT minor_category FROM top5_2008)
  GROUP BY `year`, `minor_category`
)
SELECT
  cy.`year`,
  ROUND(100 * SUM(IF(ct.`minor_category` = 'Other Theft',               ct.cat_total, 0)) / cy.city_total, 2) AS `Other Theft`,
  ROUND(100 * SUM(IF(ct.`minor_category` = 'Theft From Motor Vehicle',  ct.cat_total, 0)) / cy.city_total, 2) AS `Theft From Motor Vehicle`,
  ROUND(100 * SUM(IF(ct.`minor_category` = 'Possession Of Drugs',       ct.cat_total, 0)) / cy.city_total, 2) AS `Possession Of Drugs`,
  ROUND(100 * SUM(IF(ct.`minor_category` = 'Burglary in a Dwelling',    ct.cat_total, 0)) / cy.city_total, 2) AS `Burglary in a Dwelling`,
  ROUND(100 * SUM(IF(ct.`minor_category` = 'Assault with Injury',       ct.cat_total, 0)) / cy.city_total, 2) AS `Assault with Injury`
FROM city_year AS cy
LEFT JOIN cat_year AS ct USING (`year`)
GROUP BY cy.`year`, cy.city_total
ORDER BY cy.`year`;