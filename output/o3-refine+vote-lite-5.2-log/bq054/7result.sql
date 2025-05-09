-- Top 10 tree species by change in total tree count between 1995 and 2015
WITH species_year AS (
  SELECT
    -- derive census year from the table suffix
    CASE _TABLE_SUFFIX
      WHEN '1995' THEN 1995
      WHEN '2005' THEN 2005
      WHEN '2015' THEN 2015
    END                                                   AS census_year,
    UPPER(spc_latin)                                      AS species_latin_upper,
    spc_common                                            AS common_name,
    -- flag dead trees (status field contains the word 'DEAD')
    CASE WHEN REGEXP_CONTAINS(UPPER(status), r'DEAD') 
         THEN 1 ELSE 0 END                               AS is_dead
  FROM `bigquery-public-data.new_york.tree_census_*`
  WHERE _TABLE_SUFFIX IN ('1995','2005','2015')
    AND spc_latin IS NOT NULL
    AND spc_latin != ''
),
species_agg AS (
  SELECT
    species_latin_upper,
    ANY_VALUE(common_name)                                                    AS common_name,

    -- total counts per year
    SUM(CASE WHEN census_year = 1995 THEN 1 ELSE 0 END)                       AS total_1995,
    SUM(CASE WHEN census_year = 2005 THEN 1 ELSE 0 END)                       AS total_2005,
    SUM(CASE WHEN census_year = 2015 THEN 1 ELSE 0 END)                       AS total_2015,

    -- alive counts per year
    SUM(CASE WHEN census_year = 1995 AND is_dead = 0 THEN 1 ELSE 0 END)       AS alive_1995,
    SUM(CASE WHEN census_year = 2005 AND is_dead = 0 THEN 1 ELSE 0 END)       AS alive_2005,
    SUM(CASE WHEN census_year = 2015 AND is_dead = 0 THEN 1 ELSE 0 END)       AS alive_2015,

    -- dead counts per year
    SUM(CASE WHEN census_year = 1995 AND is_dead = 1 THEN 1 ELSE 0 END)       AS dead_1995,
    SUM(CASE WHEN census_year = 2005 AND is_dead = 1 THEN 1 ELSE 0 END)       AS dead_2005,
    SUM(CASE WHEN census_year = 2015 AND is_dead = 1 THEN 1 ELSE 0 END)       AS dead_2015
  FROM species_year
  GROUP BY species_latin_upper
),
final AS (
  SELECT
    species_latin_upper                                AS latin_name,
    common_name,

    -- totals
    total_1995, total_2005, total_2015,
    total_2015 - total_1995                            AS total_growth_1995_2015,

    -- alive
    alive_1995, alive_2005, alive_2015,
    alive_2015 - alive_1995                            AS alive_growth_1995_2015,

    -- dead
    dead_1995,  dead_2005,  dead_2015,
    dead_2015  - dead_1995                             AS dead_growth_1995_2015
  FROM species_agg
)
SELECT *
FROM final
ORDER BY total_growth_1995_2015 DESC, latin_name
LIMIT 10;