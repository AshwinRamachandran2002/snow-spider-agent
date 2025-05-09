/*  Top-10 NY tree species with biggest population jump (1995 ➜ 2015)  */
WITH cte_1995 AS (
    SELECT
        UPPER("spc_latin")                                    AS "latin_name",
        MAX("spc_common")                                     AS "common_name_1995",
        COUNT(*)                                              AS "total_1995",
        SUM(CASE WHEN "status" = 'Alive'            THEN 1 ELSE 0 END) AS "alive_1995",
        SUM(CASE WHEN "status" IN ('Dead','Stump') THEN 1 ELSE 0 END) AS "dead_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER("spc_latin")
),
cte_2015 AS (
    SELECT
        UPPER("spc_latin")                                    AS "latin_name",
        MAX("spc_common")                                     AS "common_name_2015",
        COUNT(*)                                              AS "total_2015",
        SUM(CASE WHEN "status" = 'Alive'            THEN 1 ELSE 0 END) AS "alive_2015",
        SUM(CASE WHEN "status" IN ('Dead','Stump') THEN 1 ELSE 0 END) AS "dead_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER("spc_latin")
)

SELECT
    COALESCE(t15."latin_name", t95."latin_name")                        AS "latin_name",
    COALESCE(t15."common_name_2015", t95."common_name_1995")            AS "common_name",
    NVL(t95."total_1995", 0)                                            AS "total_1995",
    NVL(t95."alive_1995", 0)                                            AS "alive_1995",
    NVL(t95."dead_1995", 0)                                             AS "dead_1995",
    NVL(t15."total_2015", 0)                                            AS "total_2015",
    NVL(t15."alive_2015", 0)                                            AS "alive_2015",
    NVL(t15."dead_2015", 0)                                             AS "dead_2015",
    NVL(t15."total_2015", 0) - NVL(t95."total_1995", 0)                 AS "total_growth",
    NVL(t15."alive_2015", 0) - NVL(t95."alive_1995", 0)                 AS "alive_growth",
    NVL(t15."dead_2015", 0)  - NVL(t95."dead_1995", 0)                  AS "dead_growth"
FROM cte_1995 t95
FULL OUTER JOIN cte_2015 t15
       ON t15."latin_name" = t95."latin_name"
ORDER BY "total_growth" DESC NULLS LAST
LIMIT 10;