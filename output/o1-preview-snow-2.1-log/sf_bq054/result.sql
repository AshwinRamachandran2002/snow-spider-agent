SELECT
    COALESCE(t95."Species_Latin", t15."Species_Latin") AS "Species_Latin",
    COALESCE(t95."Count_1995_Total", 0) AS "Count_1995_Total",
    COALESCE(t95."Count_1995_Alive", 0) AS "Count_1995_Alive",
    COALESCE(t95."Count_1995_Dead", 0) AS "Count_1995_Dead",
    COALESCE(t15."Count_2015_Total", 0) AS "Count_2015_Total",
    COALESCE(t15."Count_2015_Alive", 0) AS "Count_2015_Alive",
    COALESCE(t15."Count_2015_Dead", 0) AS "Count_2015_Dead",
    ROUND((COALESCE(t15."Count_2015_Total", 0) - COALESCE(t95."Count_1995_Total", 0)), 4) AS "Growth_in_Total_Population"
FROM
    (
        SELECT
            TRIM(SPLIT_PART(LOWER("spc_latin"), ' ', 1) || ' ' || SPLIT_PART(LOWER("spc_latin"), ' ', 2)) AS "Species_Latin",
            COUNT(*) AS "Count_1995_Total",
            SUM(CASE WHEN LOWER(TRIM("status")) NOT IN ('dead', 'stump') THEN 1 ELSE 0 END) AS "Count_1995_Alive",
            SUM(CASE WHEN LOWER(TRIM("status")) IN ('dead', 'stump') THEN 1 ELSE 0 END) AS "Count_1995_Dead"
        FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_1995"
        WHERE "spc_latin" IS NOT NULL AND TRIM("spc_latin") <> ''
        GROUP BY "Species_Latin"
    ) t95
FULL OUTER JOIN
    (
        SELECT
            TRIM(SPLIT_PART(LOWER("spc_latin"), ' ', 1) || ' ' || SPLIT_PART(LOWER("spc_latin"), ' ', 2)) AS "Species_Latin",
            COUNT(*) AS "Count_2015_Total",
            SUM(CASE WHEN LOWER(TRIM("status")) = 'alive' THEN 1 ELSE 0 END) AS "Count_2015_Alive",
            SUM(CASE WHEN LOWER(TRIM("status")) = 'dead' THEN 1 ELSE 0 END) AS "Count_2015_Dead"
        FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_2015"
        WHERE "spc_latin" IS NOT NULL AND TRIM("spc_latin") <> ''
        GROUP BY "Species_Latin"
    ) t15
ON t95."Species_Latin" = t15."Species_Latin"
WHERE COALESCE(t95."Species_Latin", t15."Species_Latin") <> ''
ORDER BY "Growth_in_Total_Population" DESC NULLS LAST
LIMIT 10;