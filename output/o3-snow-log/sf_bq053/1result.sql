WITH
-- count of trees per species in 1995 that are NOT marked as dead
cnt_1995 AS (
    SELECT
        UPPER(TRIM("spc_latin"))          AS species_name,
        COUNT(*)                          AS cnt_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER(COALESCE("status",'ALIVE')) NOT LIKE '%DEAD%'
    GROUP BY species_name
),

-- count of trees per species in 2015 that are ALIVE
cnt_2015 AS (
    SELECT
        UPPER(TRIM("spc_latin"))          AS species_name,
        COUNT(*)                          AS cnt_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "status" = 'Alive'
    GROUP BY species_name
),

-- species lookup with fall color
species_lkp AS (
    SELECT
        UPPER(TRIM("species_scientific_name"))  AS species_name,
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
)

SELECT
    sl."fall_color",
    SUM( COALESCE(c15.cnt_2015,0) - COALESCE(c95.cnt_1995,0) )  AS change_in_trees
FROM species_lkp            sl
LEFT JOIN cnt_1995          c95 ON sl.species_name = c95.species_name
LEFT JOIN cnt_2015          c15 ON sl.species_name = c15.species_name
GROUP BY sl."fall_color"
ORDER BY change_in_trees DESC NULLS LAST;