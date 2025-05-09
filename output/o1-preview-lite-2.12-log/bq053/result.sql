WITH
  counts_1995 AS (
    SELECT
      UPPER(ts.species_scientific_name) AS species,
      ts.fall_color,
      COUNT(*) AS tree_count_1995
    FROM
      `bigquery-public-data.new_york.tree_census_1995` AS tc1995
    JOIN
      `bigquery-public-data.new_york.tree_species` AS ts
    ON
      UPPER(tc1995.spc_latin) = UPPER(ts.species_scientific_name)
    WHERE
      LOWER(tc1995.status) NOT LIKE '%dead%'
      AND tc1995.spc_latin IS NOT NULL AND tc1995.spc_latin != ''
      AND ts.species_scientific_name IS NOT NULL AND ts.species_scientific_name != ''
      AND ts.fall_color IS NOT NULL AND ts.fall_color != ''
    GROUP BY
      species,
      ts.fall_color
  ),
  counts_2015 AS (
    SELECT
      UPPER(ts.species_scientific_name) AS species,
      ts.fall_color,
      COUNT(*) AS tree_count_2015
    FROM
      `bigquery-public-data.new_york.tree_census_2015` AS tc2015
    JOIN
      `bigquery-public-data.new_york.tree_species` AS ts
    ON
      UPPER(tc2015.spc_latin) = UPPER(ts.species_scientific_name)
    WHERE
      LOWER(tc2015.status) = 'alive'
      AND tc2015.spc_latin IS NOT NULL AND tc2015.spc_latin != ''
      AND ts.species_scientific_name IS NOT NULL AND ts.species_scientific_name != ''
      AND ts.fall_color IS NOT NULL AND ts.fall_color != ''
    GROUP BY
      species,
      ts.fall_color
  )
SELECT
  COALESCE(c2015.fall_color, c1995.fall_color) AS fall_color,
  SUM(COALESCE(c2015.tree_count_2015, 0) - COALESCE(c1995.tree_count_1995, 0)) AS total_change_in_number_of_trees
FROM
  counts_2015 AS c2015
FULL OUTER JOIN
  counts_1995 AS c1995
ON
  c2015.species = c1995.species
  AND c2015.fall_color = c1995.fall_color
WHERE
  COALESCE(c2015.fall_color, c1995.fall_color) IS NOT NULL
  AND COALESCE(c2015.fall_color, c1995.fall_color) != ''
GROUP BY
  fall_color
ORDER BY
  total_change_in_number_of_trees DESC;