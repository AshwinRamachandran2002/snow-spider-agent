WITH
species AS (                       -- scientific name & fall color master list
    SELECT
        UPPER("species_scientific_name")  AS "SCI_NAME",
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
),
census_1995 AS (                   -- trees that were NOT dead in 1995
    SELECT
        UPPER("spc_latin")         AS "SCI_NAME",
        COUNT(*)                   AS "CNT_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER("status") <> 'DEAD'
    GROUP BY UPPER("spc_latin")
),
census_2015 AS (                   -- trees that were ALIVE in 2015
    SELECT
        UPPER("spc_latin")         AS "SCI_NAME",
        COUNT(*)                   AS "CNT_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER("status") = 'ALIVE'
    GROUP BY UPPER("spc_latin")
),
species_diff AS (                  -- change for each species
    SELECT
        s."fall_color",
        COALESCE(c15."CNT_2015",0) - COALESCE(c95."CNT_1995",0)  AS "DIFF_PER_SPECIES"
    FROM species                s
    LEFT JOIN census_1995   c95 ON s."SCI_NAME" = c95."SCI_NAME"
    LEFT JOIN census_2015   c15 ON s."SCI_NAME" = c15."SCI_NAME"
)
SELECT
    "fall_color",
    SUM("DIFF_PER_SPECIES") AS "CHANGE_IN_LIVING_TREES"
FROM species_diff
GROUP BY "fall_color"
ORDER BY "fall_color";