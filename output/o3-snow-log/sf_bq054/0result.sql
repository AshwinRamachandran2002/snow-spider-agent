/* Top-10 tree species – counts in 1995 vs. 2015 plus growth */
WITH c95 AS (
    SELECT
        UPPER(TRIM("spc_latin"))                         AS latin_name,
        MAX(TRIM("spc_common"))                          AS common_name_95,
        COUNT(*)                                         AS total_1995,
        SUM(CASE WHEN UPPER(TRIM("status")) IN ('DEAD','STUMP')
                 THEN 1 ELSE 0 END)                     AS dead_1995,
        SUM(CASE WHEN UPPER(TRIM("status")) IN ('DEAD','STUMP')
                 THEN 0 ELSE 1 END)                     AS alive_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE TRIM("spc_latin") IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER(TRIM("spc_latin"))
),
c15 AS (
    SELECT
        UPPER(TRIM("spc_latin"))                         AS latin_name,
        MAX(TRIM("spc_common"))                          AS common_name_15,
        COUNT(*)                                         AS total_2015,
        SUM(CASE WHEN UPPER(TRIM("status")) IN ('DEAD','STUMP')
                 THEN 1 ELSE 0 END)                     AS dead_2015,
        SUM(CASE WHEN UPPER(TRIM("status")) = 'ALIVE'
                 THEN 1 ELSE 0 END)                     AS alive_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE TRIM("spc_latin") IS NOT NULL
      AND TRIM("spc_latin") <> ''
    GROUP BY UPPER(TRIM("spc_latin"))
),
combined AS (
    SELECT
        c15.latin_name,
        COALESCE(c15.common_name_15, c95.common_name_95)          AS common_name,
        COALESCE(c95.total_1995, 0)                               AS total_1995,
        COALESCE(c95.alive_1995, 0)                               AS alive_1995,
        COALESCE(c95.dead_1995 , 0)                               AS dead_1995,
        COALESCE(c15.total_2015, 0)                               AS total_2015,
        COALESCE(c15.alive_2015, 0)                               AS alive_2015,
        COALESCE(c15.dead_2015 , 0)                               AS dead_2015,
        COALESCE(c15.total_2015, 0) - COALESCE(c95.total_1995, 0) AS growth_total,
        COALESCE(c15.alive_2015, 0) - COALESCE(c95.alive_1995, 0) AS growth_alive,
        COALESCE(c15.dead_2015 , 0) - COALESCE(c95.dead_1995 , 0) AS growth_dead
    FROM c15
    LEFT JOIN c95 USING (latin_name)
)
SELECT
    latin_name,
    common_name,
    total_1995,
    alive_1995,
    dead_1995,
    total_2015,
    alive_2015,
    dead_2015,
    growth_total,
    growth_alive,
    growth_dead
FROM combined
ORDER BY growth_total DESC NULLS LAST
LIMIT 10;