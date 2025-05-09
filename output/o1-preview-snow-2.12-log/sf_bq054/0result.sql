SELECT
    COALESCE(t95."spc_latin", t15."spc_latin") AS "Latin_Name",
    COALESCE(t95."spc_common", t15."spc_common") AS "Common_Name",
    COALESCE(t95."Total_Trees_1995", 0) AS "Total_Trees_1995",
    COALESCE(t95."Alive_1995", 0) AS "Alive_1995",
    COALESCE(t95."Dead_1995", 0) AS "Dead_1995",
    COALESCE(t15."Total_Trees_2015", 0) AS "Total_Trees_2015",
    COALESCE(t15."Alive_2015", 0) AS "Alive_2015",
    COALESCE(t15."Dead_2015", 0) AS "Dead_2015",
    (COALESCE(t15."Total_Trees_2015", 0) - COALESCE(t95."Total_Trees_1995", 0)) AS "Growth_in_Total_Trees",
    (COALESCE(t15."Alive_2015", 0) - COALESCE(t95."Alive_1995", 0)) AS "Growth_in_Alive_Trees",
    (COALESCE(t15."Dead_2015", 0) - COALESCE(t95."Dead_1995", 0)) AS "Growth_in_Dead_Trees"
FROM
    (
        SELECT
            UPPER("spc_latin") AS "spc_latin",
            MAX("spc_common") AS "spc_common",
            COUNT(*) AS "Total_Trees_1995",
            SUM(CASE WHEN "status" IN ('Good', 'Fair', 'Excellent', 'Poor', 'Critical') THEN 1 ELSE 0 END) AS "Alive_1995",
            SUM(CASE WHEN "status" = 'Dead' THEN 1 ELSE 0 END) AS "Dead_1995"
        FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_1995"
        WHERE "spc_latin" IS NOT NULL AND "spc_latin" != ''
        GROUP BY UPPER("spc_latin")
    ) t95
FULL OUTER JOIN
    (
        SELECT
            UPPER("spc_latin") AS "spc_latin",
            MAX("spc_common") AS "spc_common",
            COUNT(*) AS "Total_Trees_2015",
            SUM(CASE WHEN "status" = 'Alive' THEN 1 ELSE 0 END) AS "Alive_2015",
            SUM(CASE WHEN "status" = 'Dead' THEN 1 ELSE 0 END) AS "Dead_2015"
        FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_2015"
        WHERE "spc_latin" IS NOT NULL AND "spc_latin" != ''
        GROUP BY UPPER("spc_latin")
    ) t15
ON t95."spc_latin" = t15."spc_latin"
WHERE COALESCE(t95."spc_latin", t15."spc_latin") != ''
ORDER BY
    (COALESCE(t15."Total_Trees_2015", 0) - COALESCE(t95."Total_Trees_1995", 0)) DESC NULLS LAST
LIMIT 10;