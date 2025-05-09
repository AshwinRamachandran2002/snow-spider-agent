WITH species_counts_1995 AS (
  SELECT
    UPPER(spc_latin) AS species_name,
    COUNT(*) AS tree_count_1995
  FROM
    `bigquery-public-data.new_york.tree_census_1995`
  WHERE
    UPPER(status) != 'DEAD'
    AND spc_latin IS NOT NULL
    AND spc_latin != ''
  GROUP BY
    species_name
),
species_counts_2015 AS (
  SELECT
    UPPER(spc_latin) AS species_name,
    COUNT(*) AS tree_count_2015
  FROM
    `bigquery-public-data.new_york.tree_census_2015`
  WHERE
    UPPER(status) = 'ALIVE'
    AND spc_latin IS NOT NULL
    AND spc_latin != ''
  GROUP BY
    species_name
),
species_fall_color AS (
  SELECT
    UPPER(species_scientific_name) AS species_name,
    fall_color
  FROM
    `bigquery-public-data.new_york.tree_species`
  WHERE
    species_scientific_name IS NOT NULL
    AND species_scientific_name != ''
    AND fall_color IS NOT NULL
)

SELECT
    fc.fall_color,
    SUM(IFNULL(sc2015.tree_count_2015, 0) - IFNULL(sc1995.tree_count_1995, 0)) AS total_change_in_number_of_trees
FROM
    species_fall_color fc
LEFT JOIN
    species_counts_1995 sc1995 ON fc.species_name = sc1995.species_name
LEFT JOIN
    species_counts_2015 sc2015 ON fc.species_name = sc2015.species_name
GROUP BY
    fc.fall_color
ORDER BY
    fc.fall_color;