WITH living_1995 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS sci_name,
    COUNT(*)               AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) NOT IN ('DEAD','STUMP')
  GROUP BY sci_name
),
living_2015 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS sci_name,
    COUNT(*)               AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) NOT IN ('DEAD','STUMP')
  GROUP BY sci_name
),
species_change AS (
  SELECT
    UPPER(TRIM(ts.species_scientific_name))            AS sci_name,
    UPPER(TRIM(REPLACE(ts.fall_color, ' ', '')))       AS fall_color,
    IFNULL(l15.cnt_2015, 0) - IFNULL(l95.cnt_1995, 0)  AS net_change
  FROM `bigquery-public-data.new_york.tree_species` AS ts
  LEFT JOIN living_1995 l95 ON UPPER(TRIM(ts.species_scientific_name)) = l95.sci_name
  LEFT JOIN living_2015 l15 ON UPPER(TRIM(ts.species_scientific_name)) = l15.sci_name
  WHERE ts.fall_color IS NOT NULL
)
SELECT
  fall_color,
  SUM(net_change) AS total_change
FROM species_change
GROUP BY fall_color
ORDER BY total_change DESC;