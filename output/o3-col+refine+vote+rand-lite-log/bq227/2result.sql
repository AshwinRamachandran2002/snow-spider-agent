-- Annual percentage share of 2008’s TOP-5 minor crime categories
WITH yearly AS (
  SELECT
    year,
    SUM(value) AS total_year,
    SUM(CASE WHEN minor_category = 'Other Theft'              THEN value ELSE 0 END) AS other_theft,
    SUM(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN value ELSE 0 END) AS theft_from_mv,
    SUM(CASE WHEN minor_category = 'Possession Of Drugs'      THEN value ELSE 0 END) AS possession_of_drugs,
    SUM(CASE WHEN minor_category = 'Burglary in a Dwelling'   THEN value ELSE 0 END) AS burglary_dwelling,
    SUM(CASE WHEN minor_category = 'Assault with Injury'      THEN value ELSE 0 END) AS assault_with_injury
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
)
SELECT
  year,
  ROUND(100 * other_theft         / total_year, 2) AS pct_other_theft,
  ROUND(100 * theft_from_mv       / total_year, 2) AS pct_theft_from_mv,
  ROUND(100 * possession_of_drugs / total_year, 2) AS pct_possession_of_drugs,
  ROUND(100 * burglary_dwelling   / total_year, 2) AS pct_burglary_dwelling,
  ROUND(100 * assault_with_injury / total_year, 2) AS pct_assault_with_injury
FROM yearly
ORDER BY year;