SELECT UPPER(TRIM(COALESCE(t1."spc_latin", t2."spc_latin"))) AS "Latin_Name",
       COALESCE(s."species_common_name", t1."spc_common", t2."spc_common") AS "Common_Name",
       COALESCE(t1.total_trees_1995, 0) AS "Total_Trees_1995",
       COALESCE(t1.alive_1995, 0) AS "Alive_1995",
       COALESCE(t1.dead_1995, 0) AS "Dead_1995",
       COALESCE(t2.total_trees_2015, 0) AS "Total_Trees_2015",
       COALESCE(t2.alive_2015, 0) AS "Alive_2015",
       COALESCE(t2.dead_2015, 0) AS "Dead_2015",
       (COALESCE(t2.total_trees_2015, 0) - COALESCE(t1.total_trees_1995, 0)) AS "Growth_in_Total_Trees",
       (COALESCE(t2.alive_2015, 0) - COALESCE(t1.alive_1995, 0)) AS "Growth_in_Alive_Trees",
       (COALESCE(t2.dead_2015, 0) - COALESCE(t1.dead_1995, 0)) AS "Growth_in_Dead_Trees"
FROM
    (SELECT UPPER(TRIM("spc_latin")) AS "spc_latin",
            MAX("spc_common") AS "spc_common",
            COUNT(*) AS total_trees_1995,
            SUM(CASE WHEN "status" NOT IN ('Dead', 'Stump', 'Planting Space', 'Shaft') THEN 1 ELSE 0 END) AS alive_1995,
            SUM(CASE WHEN "status" = 'Dead' THEN 1 ELSE 0 END) AS dead_1995
     FROM NEW_YORK.NEW_YORK."TREE_CENSUS_1995"
     WHERE "spc_latin" IS NOT NULL AND TRIM("spc_latin") <> ''
     GROUP BY UPPER(TRIM("spc_latin"))) t1
FULL OUTER JOIN
    (SELECT UPPER(TRIM("spc_latin")) AS "spc_latin",
            MAX("spc_common") AS "spc_common",
            COUNT(*) AS total_trees_2015,
            SUM(CASE WHEN "status" = 'Alive' THEN 1 ELSE 0 END) AS alive_2015,
            SUM(CASE WHEN "status" = 'Dead' THEN 1 ELSE 0 END) AS dead_2015
     FROM NEW_YORK.NEW_YORK."TREE_CENSUS_2015"
     WHERE "spc_latin" IS NOT NULL AND TRIM("spc_latin") <> ''
     GROUP BY UPPER(TRIM("spc_latin"))) t2
ON t1."spc_latin" = t2."spc_latin"
LEFT JOIN NEW_YORK.NEW_YORK."TREE_SPECIES" s
    ON UPPER(s."species_scientific_name") = t1."spc_latin"
       OR UPPER(s."species_scientific_name") = t2."spc_latin"
WHERE UPPER(TRIM(COALESCE(t1."spc_latin", t2."spc_latin"))) <> ''
ORDER BY "Growth_in_Total_Trees" DESC NULLS LAST
LIMIT 10;