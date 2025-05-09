-- Calculate change in living-tree counts (1995 → 2015) aggregated by fall-color
WITH
-- 1. 1995 census: trees that were NOT marked dead
c95 AS (
  SELECT
    UPPER(`spc_latin`) AS species,
    COUNT(*)           AS cnt_1995_not_dead
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(`status`) <> 'DEAD'
  GROUP BY species
),

-- 2. 2015 census: trees that were marked ALIVE
c15 AS (
  SELECT
    UPPER(`spc_latin`) AS species,
    COUNT(*)           AS cnt_2015_alive
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(`status`) = 'ALIVE'
  GROUP BY species
),

-- 3. Species-level difference between the two years
diff AS (
  SELECT
    COALESCE(c95.species, c15.species)                         AS species,
    IFNULL(c95.cnt_1995_not_dead, 0) -
    IFNULL(c15.cnt_2015_alive,     0)                           AS change_in_count
  FROM c95
  FULL JOIN c15 USING (species)
)

-- 4. Attach fall-color classification and aggregate
SELECT
  ts.`fall_color`,
  SUM(diff.change_in_count) AS total_change_in_tree_count
FROM diff
JOIN `bigquery-public-data.new_york.tree_species` AS ts
  ON UPPER(ts.`species_scientific_name`) = diff.species
GROUP BY ts.`fall_color`
ORDER BY total_change_in_tree_count DESC;