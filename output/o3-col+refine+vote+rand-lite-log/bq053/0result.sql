/* Change in number of living NYC street-trees (1995 → 2015) by autumn-leaf color */
WITH alive_1995 AS (
  SELECT
    UPPER(spc_latin) AS species_uc,
    COUNT(*)         AS cnt_1995                -- trees *not* recorded as dead
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) NOT LIKE '%DEAD%'         -- keeps Poor/Good/Excellent, etc.
  GROUP BY species_uc
),
alive_2015 AS (
  SELECT
    UPPER(spc_latin) AS species_uc,
    COUNT(*)         AS cnt_2015                -- trees explicitly marked alive
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
  GROUP BY species_uc
),
delta_per_species AS (                          -- 2015 – 1995 change per species
  SELECT
    COALESCE(a95.species_uc, a15.species_uc)                AS species_uc,
    IFNULL(a15.cnt_2015,0) - IFNULL(a95.cnt_1995,0)         AS delta_alive
  FROM alive_1995 a95
  FULL JOIN alive_2015 a15 USING (species_uc)
),
delta_with_color AS (                           -- attach each species’ fall color
  SELECT
    ts.fall_color,
    d.delta_alive
  FROM delta_per_species d
  JOIN (
    SELECT
      UPPER(species_scientific_name) AS species_uc,
      fall_color
    FROM `bigquery-public-data.new_york.tree_species`
  ) ts USING (species_uc)
)
SELECT
  fall_color,
  SUM(delta_alive) AS total_change_living_trees
FROM delta_with_color
GROUP BY fall_color
ORDER BY total_change_living_trees DESC;