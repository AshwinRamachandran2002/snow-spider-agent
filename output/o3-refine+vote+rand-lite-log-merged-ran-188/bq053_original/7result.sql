WITH census_1995 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*) AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) != 'DEAD'            -- keep all trees that are not marked as dead
  GROUP BY species
),
census_2015 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*) AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'            -- count only living trees
  GROUP BY species
),
species_change AS (
  -- combine the two censuses and compute change per species
  SELECT
    COALESCE(c15.species, c95.species)            AS species,
    IFNULL(c15.cnt_2015, 0)                       AS cnt_2015,
    IFNULL(c95.cnt_1995, 0)                       AS cnt_1995,
    IFNULL(c15.cnt_2015, 0) - IFNULL(c95.cnt_1995, 0) AS change
  FROM census_1995 c95
  FULL JOIN census_2015 c15
  ON c95.species = c15.species
),
fall_color_change AS (
  -- attach fall‑color information
  SELECT
    ts.fall_color,
    sc.change
  FROM species_change sc
  JOIN `bigquery-public-data.new_york.tree_species` ts
    ON UPPER(ts.species_scientific_name) = sc.species
)
SELECT
  fall_color,
  SUM(change) AS total_change_1995_to_2015
FROM fall_color_change
GROUP BY fall_color
ORDER BY total_change_1995_to_2015 DESC;