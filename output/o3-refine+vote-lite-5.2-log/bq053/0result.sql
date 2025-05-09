WITH
/* --- count of trees (not dead) in the 1995 census ----------------------- */
census_1995 AS (
  SELECT
    UPPER(spc_latin)            AS species_latin,
    COUNT(*)                    AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) != 'DEAD'          -- keep every tree that is not marked as dead
  GROUP BY species_latin
),

/* --- count of trees (alive) in the 2015 census -------------------------- */
census_2015 AS (
  SELECT
    UPPER(spc_latin)            AS species_latin,
    COUNT(*)                    AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'          -- keep only the living trees
  GROUP BY species_latin
),

/* --- scientific names & their fall‑color classification ----------------- */
species_dim AS (
  SELECT
    UPPER(species_scientific_name) AS species_latin,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
)

/* --- aggregate the net change by fall color ----------------------------- */
SELECT
  sd.fall_color,
  SUM( COALESCE(c15.cnt_2015,0) - COALESCE(c95.cnt_1995,0) ) AS net_change_in_trees
FROM  species_dim sd
LEFT JOIN census_1995 c95 USING (species_latin)
LEFT JOIN census_2015 c15 USING (species_latin)
GROUP BY sd.fall_color
ORDER BY net_change_in_trees DESC;