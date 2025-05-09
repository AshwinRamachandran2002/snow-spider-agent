WITH census_1995 AS (
    SELECT
        UPPER("spc_latin")                                   AS "LATIN",
        COUNT(*)                                             AS "TOTAL_1995",
        SUM(CASE WHEN UPPER("status") = 'ALIVE' THEN 1 END)  AS "ALIVE_1995",
        SUM(CASE WHEN UPPER("status") = 'DEAD'  THEN 1 END)  AS "DEAD_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER("spc_latin")
),
census_2015 AS (
    SELECT
        UPPER("spc_latin")                                   AS "LATIN",
        MAX("spc_common")                                    AS "COMMON_NAME",
        COUNT(*)                                             AS "TOTAL_2015",
        SUM(CASE WHEN UPPER("status") = 'ALIVE' THEN 1 END)  AS "ALIVE_2015",
        SUM(CASE WHEN UPPER("status") = 'DEAD'  THEN 1 END)  AS "DEAD_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER("spc_latin")
)
SELECT
    c15."LATIN"                                         AS "LATIN_NAME_UPPER",
    c15."COMMON_NAME",
    COALESCE(c95."TOTAL_1995", 0)                       AS "TOTAL_1995",
    c15."TOTAL_2015",
    c15."TOTAL_2015" - COALESCE(c95."TOTAL_1995", 0)    AS "TOTAL_GROWTH",
    COALESCE(c95."ALIVE_1995", 0)                       AS "ALIVE_1995",
    c15."ALIVE_2015",
    c15."ALIVE_2015" - COALESCE(c95."ALIVE_1995", 0)    AS "ALIVE_GROWTH",
    COALESCE(c95."DEAD_1995", 0)                        AS "DEAD_1995",
    c15."DEAD_2015",
    c15."DEAD_2015" - COALESCE(c95."DEAD_1995", 0)      AS "DEAD_GROWTH"
FROM census_2015 c15
LEFT JOIN census_1995 c95 USING ("LATIN")
ORDER BY "TOTAL_GROWTH" DESC NULLS LAST
LIMIT 10;