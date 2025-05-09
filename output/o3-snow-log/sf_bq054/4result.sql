/*  Top-10 NYC tree species by increase in total count from 1995→2015  */
WITH
-- 1995 census aggregated by scientific (Latin) name
y95 AS (
    SELECT
        UPPER(TRIM("spc_latin"))                        AS latin_name,
        MAX("spc_common")                              AS common_name,
        COUNT(*)                                       AS cnt_1995_total,
        SUM( CASE
                 WHEN UPPER("status") IN ('POOR','FAIR','GOOD','EXCELLENT')
                 THEN 1 ELSE 0 END )                   AS cnt_1995_alive,
        SUM( CASE
                 WHEN UPPER("status") IN ('POOR','FAIR','GOOD','EXCELLENT')
                 THEN 0 ELSE 1 END )                   AS cnt_1995_dead
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER(TRIM("spc_latin"))
),
-- 2015 census aggregated by scientific (Latin) name
y15 AS (
    SELECT
        UPPER(TRIM("spc_latin"))                        AS latin_name,
        MAX("spc_common")                              AS common_name,
        COUNT(*)                                       AS cnt_2015_total,
        SUM( CASE
                 WHEN UPPER("status") = 'ALIVE'
                 THEN 1 ELSE 0 END )                   AS cnt_2015_alive,
        SUM( CASE
                 WHEN UPPER("status") = 'ALIVE'
                 THEN 0 ELSE 1 END )                   AS cnt_2015_dead
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE "spc_latin" IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER(TRIM("spc_latin"))
),
-- Combine both years and compute growth figures
joined AS (
    SELECT
        COALESCE(y15.latin_name , y95.latin_name)                     AS latin_name,
        COALESCE(y15.common_name, y95.common_name)                   AS common_name,

        NVL(y95.cnt_1995_total ,0)  AS cnt_1995_total,
        NVL(y95.cnt_1995_alive ,0)  AS cnt_1995_alive,
        NVL(y95.cnt_1995_dead  ,0)  AS cnt_1995_dead,

        NVL(y15.cnt_2015_total ,0)  AS cnt_2015_total,
        NVL(y15.cnt_2015_alive ,0)  AS cnt_2015_alive,
        NVL(y15.cnt_2015_dead  ,0)  AS cnt_2015_dead,

        NVL(y15.cnt_2015_total ,0) - NVL(y95.cnt_1995_total ,0)  AS growth_total,
        NVL(y15.cnt_2015_alive ,0) - NVL(y95.cnt_1995_alive ,0)  AS growth_alive,
        NVL(y15.cnt_2015_dead  ,0) - NVL(y95.cnt_1995_dead  ,0)  AS growth_dead
    FROM y95
    FULL OUTER JOIN y15
      ON y15.latin_name = y95.latin_name
)
SELECT
    latin_name,
    common_name,
    cnt_1995_total,
    cnt_1995_alive,
    cnt_1995_dead,
    cnt_2015_total,
    cnt_2015_alive,
    cnt_2015_dead,
    growth_total,
    growth_alive,
    growth_dead
FROM joined
ORDER BY growth_total DESC NULLS LAST
LIMIT 10;