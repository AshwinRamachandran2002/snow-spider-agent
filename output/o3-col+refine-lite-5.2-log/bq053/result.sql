-- Change in the number of living NYC street‑trees (2015 vs. 1995)
WITH living_1995 AS (
  SELECT
    UPPER(spc_latin) AS spc_latin,
    COUNT(*)         AS c95
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) <> 'DEAD'
  GROUP BY spc_latin
),
living_2015 AS (
  SELECT
    UPPER(spc_latin) AS spc_latin,
    COUNT(*)         AS c15
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) <> 'DEAD'
  GROUP BY spc_latin
),
species_change AS (
  SELECT
    COALESCE(l15.spc_latin, l95.spc_latin)                      AS spc_latin,
    IFNULL(l15.c15, 0) - IFNULL(l95.c95, 0)                     AS change_1995_to_2015
  FROM living_1995 AS l95
  FULL JOIN living_2015 AS l15
    ON l95.spc_latin = l15.spc_latin
),
fall_lookup AS (
  SELECT
    UPPER(species_scientific_name) AS spc_latin,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
)
SELECT
  fl.fall_color,
  SUM(sc.change_1995_to_2015) AS total_change_1995_to_2015
FROM species_change AS sc
LEFT JOIN fall_lookup AS fl
  ON fl.spc_latin = sc.spc_latin
GROUP BY fl.fall_color
ORDER BY total_change_1995_to_2015 DESC;