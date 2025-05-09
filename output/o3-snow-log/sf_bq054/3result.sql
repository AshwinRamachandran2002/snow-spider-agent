WITH c95 AS (
    SELECT 
        UPPER("spc_latin")                                       AS "latin_name",
        MAX("spc_common")                                        AS "common_name_95",
        COUNT(*)                                                 AS "total_1995",
        SUM(CASE WHEN UPPER("status") = 'ALIVE' THEN 1 ELSE 0 END) AS "alive_1995",
        SUM(CASE WHEN UPPER("status") <> 'ALIVE' THEN 1 ELSE 0 END) AS "dead_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" <> ''
    GROUP BY UPPER("spc_latin")
),
c15 AS (
    SELECT 
        UPPER("spc_latin")                                       AS "latin_name",
        MAX("spc_common")                                        AS "common_name_15",
        COUNT(*)                                                 AS "total_2015",
        SUM(CASE WHEN UPPER("status") = 'ALIVE' THEN 1 ELSE 0 END) AS "alive_2015",
        SUM(CASE WHEN UPPER("status") <> 'ALIVE' THEN 1 ELSE 0 END) AS "dead_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" <> ''
    GROUP BY UPPER("spc_latin")
)
SELECT 
    COALESCE(c15."latin_name", c95."latin_name")                                    AS "LATIN_NAME",
    COALESCE(c15."common_name_15", c95."common_name_95")                            AS "COMMON_NAME",
    COALESCE(c15."total_2015", 0)                                                   AS "TOTAL_2015",
    COALESCE(c95."total_1995", 0)                                                   AS "TOTAL_1995",
    COALESCE(c15."total_2015", 0) - COALESCE(c95."total_1995", 0)                   AS "TOTAL_GROWTH",
    COALESCE(c15."alive_2015", 0)                                                   AS "ALIVE_2015",
    COALESCE(c95."alive_1995", 0)                                                   AS "ALIVE_1995",
    COALESCE(c15."alive_2015", 0) - COALESCE(c95."alive_1995", 0)                   AS "ALIVE_GROWTH",
    COALESCE(c15."dead_2015", 0)                                                    AS "DEAD_2015",
    COALESCE(c95."dead_1995", 0)                                                    AS "DEAD_1995",
    COALESCE(c15."dead_2015", 0) - COALESCE(c95."dead_1995", 0)                     AS "DEAD_GROWTH"
FROM c95
FULL OUTER JOIN c15 
       ON c95."latin_name" = c15."latin_name"
WHERE COALESCE(c15."latin_name", c95."latin_name") IS NOT NULL
ORDER BY "TOTAL_GROWTH" DESC NULLS LAST
LIMIT 10;