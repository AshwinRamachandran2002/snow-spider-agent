WITH living_1995 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*) AS count_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) <> 'DEAD'
    AND spc_latin IS NOT NULL
  GROUP BY species
),
alive_2015 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*) AS count_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
    AND spc_latin IS NOT NULL
  GROUP BY species
),
species_change AS (
  SELECT
    COALESCE(a.species, l.species) AS species,
    IFNULL(a.count_2015, 0) - IFNULL(l.count_1995, 0) AS change_in_count
  FROM living_1995 l
  FULL JOIN alive_2015 a
  ON a.species = l.species
)
SELECT
  ts.fall_color,
  SUM(sc.change_in_count) AS total_change
FROM species_change sc
JOIN `bigquery-public-data.new_york.tree_species` ts
  ON sc.species = UPPER(ts.species_scientific_name)
GROUP BY ts.fall_color
ORDER BY total_change DESC;