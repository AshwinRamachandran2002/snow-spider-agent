WITH census_1995 AS (
    SELECT
        UPPER("spc_latin")                                   AS latin,
        "spc_common"                                         AS common,
        COUNT(*)                                             AS tot_1995,
        SUM(CASE WHEN LOWER("status") LIKE '%alive%' THEN 1 ELSE 0 END) AS alive_1995,
        SUM(CASE WHEN LOWER("status") LIKE '%dead%'  THEN 1 ELSE 0 END) AS dead_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" IS NOT NULL
      AND "spc_latin" <> ''
    GROUP BY latin, common
),
census_2015 AS (
    SELECT
        UPPER("spc_latin")                                   AS latin,
        "spc_common"                                         AS common,
        COUNT(*)                                             AS tot_2015,
        SUM(CASE WHEN LOWER("status") LIKE '%alive%' THEN 1 ELSE 0 END) AS alive_2015,
        SUM(CASE WHEN LOWER("status") LIKE '%dead%'  THEN 1 ELSE 0 END) AS dead_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" IS NOT NULL
      AND "spc_latin" <> ''
    GROUP BY latin, common
)
SELECT
    c15.latin                                               AS "LATIN",
    c15.common                                              AS "COMMON",
    COALESCE(c95.tot_1995 ,0)                               AS "TOT_1995",
    c15.tot_2015                                            AS "TOT_2015",
    COALESCE(c95.alive_1995,0)                              AS "ALIVE_1995",
    c15.alive_2015                                          AS "ALIVE_2015",
    COALESCE(c95.dead_1995 ,0)                              AS "DEAD_1995",
    c15.dead_2015                                           AS "DEAD_2015",
    c15.tot_2015  - COALESCE(c95.tot_1995 ,0)               AS "GROW_TOTAL",
    c15.alive_2015- COALESCE(c95.alive_1995,0)              AS "GROW_ALIVE",
    c15.dead_2015 - COALESCE(c95.dead_1995 ,0)              AS "GROW_DEAD"
FROM census_2015 c15
LEFT JOIN census_1995 c95
       ON c15.latin  = c95.latin
      AND c15.common = c95.common
ORDER BY "GROW_TOTAL" DESC NULLS LAST
LIMIT 10;