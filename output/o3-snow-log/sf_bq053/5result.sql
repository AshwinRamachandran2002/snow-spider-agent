WITH species_1995 AS (          -- living trees in 1995
    SELECT 
        UPPER(TRIM("spc_latin"))        AS species_scientific_name,
        COUNT(*)                        AS cnt_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER(TRIM("status")) <> 'DEAD'          -- “not marked as dead”
    GROUP BY UPPER(TRIM("spc_latin"))
),
species_2015 AS (          -- living trees in 2015
    SELECT 
        UPPER(TRIM("spc_latin"))        AS species_scientific_name,
        COUNT(*)                        AS cnt_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER(TRIM("status")) = 'ALIVE'           -- only living trees
    GROUP BY UPPER(TRIM("spc_latin"))
),
species_diff AS (          -- change per species
    SELECT 
        UPPER(TRIM(ts."species_scientific_name"))                 AS species_scientific_name,
        ts."fall_color",
        COALESCE(s15.cnt_2015, 0) - COALESCE(s95.cnt_1995, 0)     AS diff_count
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES           ts
    LEFT JOIN species_1995                        s95
           ON UPPER(TRIM(ts."species_scientific_name")) = s95.species_scientific_name
    LEFT JOIN species_2015                        s15
           ON UPPER(TRIM(ts."species_scientific_name")) = s15.species_scientific_name
)
SELECT
    "fall_color",
    SUM(diff_count)  AS total_change_in_trees
FROM species_diff
GROUP BY "fall_color"
ORDER BY "fall_color";