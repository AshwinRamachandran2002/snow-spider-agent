WITH "SPECIES" AS (
    SELECT 
        UPPER("species_scientific_name")  AS "SCI_NAME",
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
),

"C1995" AS (
    SELECT
        UPPER("spc_latin")               AS "SCI_NAME",
        COUNT(*)                         AS "CNT_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER("status") <> 'DEAD'          -- trees that are not marked as dead
    GROUP BY UPPER("spc_latin")
),

"C2015" AS (
    SELECT
        UPPER("spc_latin")               AS "SCI_NAME",
        COUNT(*)                         AS "CNT_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER("status") = 'ALIVE'          -- only living trees
    GROUP BY UPPER("spc_latin")
)

SELECT
    "SPECIES"."fall_color"                                            AS "FALL_COLOR",
    SUM( COALESCE("C2015"."CNT_2015",0) - COALESCE("C1995"."CNT_1995",0) ) 
                                                                      AS "TOTAL_CHANGE_IN_TREES"
FROM "SPECIES"
LEFT JOIN "C1995" ON "C1995"."SCI_NAME" = "SPECIES"."SCI_NAME"
LEFT JOIN "C2015" ON "C2015"."SCI_NAME" = "SPECIES"."SCI_NAME"
GROUP BY "SPECIES"."fall_color"
ORDER BY "TOTAL_CHANGE_IN_TREES" DESC NULLS LAST;