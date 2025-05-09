WITH
-- list of species with their fall color (use uppercase scientific name for matching)
species AS (
    SELECT 
        UPPER("species_scientific_name")     AS "SPECIES",
        "fall_color"                         AS "FALL_COLOR"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
),

-- count of 1995 trees that are NOT marked as dead
cnt_1995 AS (
    SELECT 
        UPPER("spc_latin")                   AS "SPECIES",
        COUNT(*)                             AS "CNT_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER("status") <> 'DEAD'
    GROUP BY UPPER("spc_latin")
),

-- count of 2015 trees that are alive
cnt_2015 AS (
    SELECT 
        UPPER("spc_latin")                   AS "SPECIES",
        COUNT(*)                             AS "CNT_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER("status") = 'ALIVE'
    GROUP BY UPPER("spc_latin")
),

-- combine counts per species and compute change (2015 – 1995)
per_species_change AS (
    SELECT
        s."SPECIES",
        s."FALL_COLOR",
        COALESCE(c15."CNT_2015", 0) - COALESCE(c95."CNT_1995", 0) AS "CHANGE"
    FROM species               s
    LEFT JOIN cnt_1995      c95 ON s."SPECIES" = c95."SPECIES"
    LEFT JOIN cnt_2015      c15 ON s."SPECIES" = c15."SPECIES"
)

-- aggregate change by fall color
SELECT
    "FALL_COLOR",
    SUM("CHANGE") AS "TOTAL_CHANGE"
FROM per_species_change
GROUP BY "FALL_COLOR"
ORDER BY "FALL_COLOR";