WITH species_colors AS (   -- map every species to its fall color
    SELECT 
        UPPER("species_scientific_name")           AS species,
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
    WHERE "fall_color" IS NOT NULL
),
count_1995 AS (           -- trees that were NOT dead in 1995
    SELECT 
        UPPER("spc_latin")                        AS species,
        COUNT(*)                                  AS cnt1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER(COALESCE("status", '')) <> 'DEAD'
    GROUP BY species
),
count_2015 AS (           -- trees that were ALIVE in 2015
    SELECT 
        UPPER("spc_latin")                        AS species,
        COUNT(*)                                  AS cnt2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER(COALESCE("status", '')) = 'ALIVE'
    GROUP BY species
),
species_diff AS (         -- change per species
    SELECT 
        sc."fall_color",
        COALESCE(c15.cnt2015, 0) - COALESCE(c95.cnt1995, 0) AS diff
    FROM species_colors sc
    LEFT JOIN count_2015 c15 ON sc.species = c15.species
    LEFT JOIN count_1995 c95 ON sc.species = c95.species
)
SELECT 
    "fall_color",
    SUM(diff) AS "tree_count_change"
FROM species_diff
GROUP BY "fall_color"
ORDER BY "tree_count_change" DESC NULLS LAST;