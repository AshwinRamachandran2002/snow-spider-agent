WITH t95_counts AS (
    SELECT UPPER(TRIM("spc_latin")) AS "species", COUNT(*) AS "count_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "status" NOT IN ('Dead', 'Stump', 'Unknown', 'Shaft', 'Planting Space')
    GROUP BY UPPER(TRIM("spc_latin"))
),
t15_counts AS (
    SELECT UPPER(TRIM("spc_latin")) AS "species", COUNT(*) AS "count_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "status" = 'Alive'
    GROUP BY UPPER(TRIM("spc_latin"))
),
species_counts AS (
    SELECT
        COALESCE(t95."species", t15."species") AS "species",
        COALESCE(t95."count_1995", 0) AS "count_1995",
        COALESCE(t15."count_2015", 0) AS "count_2015"
    FROM t95_counts t95
    FULL OUTER JOIN t15_counts t15 ON t95."species" = t15."species"
)
SELECT
    s."fall_color" AS "Fall_Color",
    SUM(sc."count_2015" - sc."count_1995") AS "Total_Change"
FROM species_counts sc
JOIN NEW_YORK.NEW_YORK.TREE_SPECIES s
  ON sc."species" = UPPER(TRIM(s."species_scientific_name"))
GROUP BY s."fall_color"
ORDER BY s."fall_color";