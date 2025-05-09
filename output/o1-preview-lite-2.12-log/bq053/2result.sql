SELECT
  species_fall_color.fall_color,
  SUM(IFNULL(trees_2015.count_2015, 0) - IFNULL(trees_1995.count_1995, 0)) AS total_change_in_number_of_trees
FROM
  (
    SELECT
      UPPER(species_scientific_name) AS species_upper,
      fall_color
    FROM
      `bigquery-public-data.new_york.tree_species`
    WHERE
      species_scientific_name IS NOT NULL
      AND species_scientific_name != ''
  ) AS species_fall_color
LEFT JOIN
  (
    SELECT
      UPPER(spc_latin) AS species_upper,
      COUNT(*) AS count_1995
    FROM
      `bigquery-public-data.new_york.tree_census_1995`
    WHERE
      status NOT IN ('Dead', 'Stump', 'Planting Space', 'Unknown')
      AND spc_latin IS NOT NULL
      AND spc_latin != ''
    GROUP BY
      species_upper
  ) AS trees_1995
ON
  species_fall_color.species_upper = trees_1995.species_upper
LEFT JOIN
  (
    SELECT
      UPPER(spc_latin) AS species_upper,
      COUNT(*) AS count_2015
    FROM
      `bigquery-public-data.new_york.tree_census_2015`
    WHERE
      status = 'Alive'
      AND spc_latin IS NOT NULL
      AND spc_latin != ''
    GROUP BY
      species_upper
  ) AS trees_2015
ON
  species_fall_color.species_upper = trees_2015.species_upper
GROUP BY
  species_fall_color.fall_color;