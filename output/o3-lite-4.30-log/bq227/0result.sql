WITH year_totals AS (            -- total crimes for each year
  SELECT
    year,
    SUM(value) AS total_crimes
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  GROUP BY year
),
year_top5_totals AS (            -- yearly totals for the five 2008‑top categories
  SELECT
    year,
    SUM(CASE WHEN minor_category = 'Other Theft'              THEN value ELSE 0 END) AS other_theft,
    SUM(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN value ELSE 0 END) AS theft_from_motor_vehicle,
    SUM(CASE WHEN minor_category = 'Possession Of Drugs'      THEN value ELSE 0 END) AS possession_of_drugs,
    SUM(CASE WHEN minor_category = 'Burglary in a Dwelling'   THEN value ELSE 0 END) AS burglary_in_a_dwelling,
    SUM(CASE WHEN minor_category = 'Assault with Injury'      THEN value ELSE 0 END) AS assault_with_injury
  FROM `bigquery-public-data.london_crime.crime_by_lsoa`
  WHERE minor_category IN (
        'Other Theft',
        'Theft From Motor Vehicle',
        'Possession Of Drugs',
        'Burglary in a Dwelling',
        'Assault with Injury')
  GROUP BY year
)
SELECT
  t.year,
  ROUND(100 * o.other_theft              / t.total_crimes, 2) AS `Other theft`,
  ROUND(100 * o.theft_from_motor_vehicle / t.total_crimes, 2) AS `Theft From Motor Vehicle`,
  ROUND(100 * o.possession_of_drugs      / t.total_crimes, 2) AS `Possession Of Drugs`,
  ROUND(100 * o.burglary_in_a_dwelling   / t.total_crimes, 2) AS `Burglary in a Dwelling`,
  ROUND(100 * o.assault_with_injury      / t.total_crimes, 2) AS `Assault with Injury`
FROM year_totals t
JOIN year_top5_totals o USING (year)
ORDER BY year;