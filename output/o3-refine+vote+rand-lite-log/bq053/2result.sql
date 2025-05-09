-- change in number of living trees by fall color from 1995 to 2015
WITH species_lookup AS (
  SELECT
    UPPER(TRIM(species_scientific_name)) AS species_name,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
),

-- 1995: trees whose status is *not* Dead
census_1995 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*) AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(TRIM(status)) <> 'DEAD'
  GROUP BY species_name
),

-- 2015: trees whose status is Alive
census_2015 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*) AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(TRIM(status)) = 'ALIVE'
  GROUP BY species_name
),

-- merge the two census counts (treat missing counts as 0)
species_counts AS (
  SELECT
    COALESCE(c95.species_name, c15.species_name) AS species_name,
    IFNULL(c95.cnt_1995, 0) AS cnt_1995,
    IFNULL(c15.cnt_2015, 0) AS cnt_2015
  FROM census_1995 c95
  FULL OUTER JOIN census_2015 c15
    ON c95.species_name = c15.species_name
),

-- compute change per species and attach fall color
species_change AS (
  SELECT
    sl.fall_color,
    sc.cnt_1995 - sc.cnt_2015 AS tree_change
  FROM species_counts sc
  JOIN species_lookup sl
    ON sc.species_name = sl.species_name
)

-- final aggregation: total change by fall color
SELECT
  fall_color,
  SUM(tree_change) AS total_change_1995_to_2015
FROM species_change
GROUP BY fall_color
ORDER BY total_change_1995_to_2015 DESC;