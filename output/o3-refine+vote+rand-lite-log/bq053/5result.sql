WITH
/* count trees that were NOT recorded as dead in the 1995 census */
living_1995 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)        AS cnt_1995
  FROM
    `bigquery-public-data.new_york.tree_census_1995`
  WHERE
    spc_latin IS NOT NULL
    AND (status IS NULL OR UPPER(status) <> 'DEAD')
  GROUP BY
    species
),

/* count trees that are alive in the 2015 census */
living_2015 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)        AS cnt_2015
  FROM
    `bigquery-public-data.new_york.tree_census_2015`
  WHERE
    spc_latin IS NOT NULL
    AND (status IS NULL OR UPPER(status) <> 'DEAD')
  GROUP BY
    species
),

/* reference table that tells us each species' fall colour */
species_ref AS (
  SELECT DISTINCT
    UPPER(species_scientific_name) AS species,
    fall_color
  FROM
    `bigquery-public-data.new_york.tree_species`
  WHERE
    fall_color IS NOT NULL
),

/* join counts for the two censuses to the species reference */
species_change AS (
  SELECT
    sr.fall_color,
    COALESCE(l15.cnt_2015, 0) AS cnt_2015,
    COALESCE(l95.cnt_1995, 0) AS cnt_1995
  FROM
    species_ref  sr
  LEFT JOIN
    living_1995 l95 USING (species)
  LEFT JOIN
    living_2015 l15 USING (species)
)

SELECT
  fall_color,
  SUM(cnt_2015 - cnt_1995) AS change_in_tree_count
FROM
  species_change
GROUP BY
  fall_color
ORDER BY
  change_in_tree_count DESC;