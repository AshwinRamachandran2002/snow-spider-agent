SELECT TRIM(UPPER(ts."fall_color")) AS "Fall_Color",
       SUM(COALESCE(alive2015."tree_count", 0) - COALESCE(alive1995."tree_count", 0)) AS "Total_Change"
FROM NEW_YORK.NEW_YORK.TREE_SPECIES ts
LEFT JOIN (
    SELECT UPPER("spc_latin") AS "species_name", COUNT(*) AS "tree_count"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "status" = 'Alive' AND "spc_latin" IS NOT NULL AND "spc_latin" != ''
    GROUP BY UPPER("spc_latin")
) alive2015 ON UPPER(ts."species_scientific_name") = alive2015."species_name"
LEFT JOIN (
    SELECT UPPER("spc_latin") AS "species_name", COUNT(*) AS "tree_count"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "status" != 'Dead' AND "spc_latin" IS NOT NULL AND "spc_latin" != ''
    GROUP BY UPPER("spc_latin")
) alive1995 ON UPPER(ts."species_scientific_name") = alive1995."species_name"
WHERE ts."fall_color" IS NOT NULL
GROUP BY TRIM(UPPER(ts."fall_color"))
ORDER BY "Total_Change" DESC NULLS LAST;