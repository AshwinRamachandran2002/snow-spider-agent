/*  Top-10 tree species: totals, alive/dead counts for 1995 vs 2015 and the growth between the two censuses  */
WITH c95 AS (   -- 1995 census aggregates
    SELECT
        UPPER("spc_latin")                                   AS "latin_name",
        MIN("spc_common")                                    AS "common_name_1995",
        COUNT(*)                                             AS "total_1995",
        SUM( CASE WHEN UPPER("status") = 'DEAD' THEN 0 ELSE 1 END ) AS "alive_1995",
        SUM( CASE WHEN UPPER("status") = 'DEAD' THEN 1 ELSE 0 END ) AS "dead_1995"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" IS NOT NULL AND "spc_latin" <> ''
    GROUP BY UPPER("spc_latin")
),
c15 AS (   -- 2015 census aggregates
    SELECT
        UPPER("spc_latin")                                   AS "latin_name",
        MIN("spc_common")                                    AS "common_name_2015",
        COUNT(*)                                             AS "total_2015",
        SUM( CASE WHEN UPPER("status") = 'ALIVE' THEN 1 ELSE 0 END ) AS "alive_2015",
        SUM( CASE WHEN UPPER("status") = 'DEAD'  THEN 1 ELSE 0 END ) AS "dead_2015"
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" IS NOT NULL AND "spc_latin" <> ''
    GROUP BY UPPER("spc_latin")
)
SELECT
    COALESCE(c15."latin_name", c95."latin_name")                                         AS "latin_name",
    COALESCE(c15."common_name_2015", c95."common_name_1995")                             AS "common_name",
    COALESCE(c95."total_1995", 0)                                                        AS "total_1995",
    COALESCE(c95."alive_1995", 0)                                                        AS "alive_1995",
    COALESCE(c95."dead_1995", 0)                                                         AS "dead_1995",
    COALESCE(c15."total_2015", 0)                                                        AS "total_2015",
    COALESCE(c15."alive_2015", 0)                                                        AS "alive_2015",
    COALESCE(c15."dead_2015", 0)                                                         AS "dead_2015",
    COALESCE(c15."total_2015", 0) - COALESCE(c95."total_1995", 0)                        AS "diff_total_2015_minus_1995",
    COALESCE(c15."alive_2015", 0) - COALESCE(c95."alive_1995", 0)                        AS "diff_alive_2015_minus_1995",
    COALESCE(c15."dead_2015", 0)  - COALESCE(c95."dead_1995", 0)                         AS "diff_dead_2015_minus_1995"
FROM c95
FULL JOIN c15 USING ("latin_name")
ORDER BY "diff_total_2015_minus_1995" DESC NULLS LAST
LIMIT 10;