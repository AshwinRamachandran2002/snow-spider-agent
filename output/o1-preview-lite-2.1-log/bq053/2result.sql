WITH species_in_both_years AS (
  SELECT DISTINCT UPPER(TRIM(tc95.spc_latin)) AS spc_latin
  FROM `bigquery-public-data.new_york.tree_census_1995` AS tc95
  JOIN `bigquery-public-data.new_york.tree_census_2015` AS tc15
    ON UPPER(TRIM(tc95.spc_latin)) = UPPER(TRIM(tc15.spc_latin))
  WHERE LOWER(tc95.status) != 'dead'
    AND LOWER(tc15.status) = 'alive'
    AND tc95.spc_latin IS NOT NULL
    AND tc15.spc_latin IS NOT NULL
),

counts_1995 AS (
  SELECT ts.fall_color, COUNT(*) AS Trees_in_1995
  FROM `bigquery-public-data.new_york.tree_census_1995` AS tc
  JOIN `bigquery-public-data.new_york.tree_species` AS ts
    ON UPPER(TRIM(tc.spc_latin)) = UPPER(TRIM(ts.species_scientific_name))
  JOIN species_in_both_years AS si
    ON UPPER(TRIM(tc.spc_latin)) = si.spc_latin
  WHERE LOWER(tc.status) != 'dead'
    AND ts.fall_color IS NOT NULL
  GROUP BY ts.fall_color
),

counts_2015 AS (
  SELECT ts.fall_color, COUNT(*) AS Trees_in_2015
  FROM `bigquery-public-data.new_york.tree_census_2015` AS tc
  JOIN `bigquery-public-data.new_york.tree_species` AS ts
    ON UPPER(TRIM(tc.spc_latin)) = UPPER(TRIM(ts.species_scientific_name))
  JOIN species_in_both_years AS si
    ON UPPER(TRIM(tc.spc_latin)) = si.spc_latin
  WHERE LOWER(tc.status) = 'alive'
    AND ts.fall_color IS NOT NULL
  GROUP BY ts.fall_color
)

SELECT COALESCE(c1995.fall_color, c2015.fall_color) AS Fall_Color,
       c1995.Trees_in_1995,
       c2015.Trees_in_2015
FROM counts_1995 AS c1995
FULL OUTER JOIN counts_2015 AS c2015
  ON c1995.fall_color = c2015.fall_color
ORDER BY Fall_Color;