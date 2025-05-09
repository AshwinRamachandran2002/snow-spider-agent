/* ----------------------------------------------------------
   Top-10 NYC tree species (by growth in total count 1995-2015)
   ‑ Uses the three decennial street-tree censuses
   ‑ Counts total, alive and dead trees for 1995, 2005, 2015
   ‑ Computes growth (2015 – 1995) for each metric
-------------------------------------------------------------*/
WITH
/* ---------- 1995 ---------- */
t1995 AS (
    SELECT
        UPPER("spc_latin")                       AS latin_name ,
        "spc_common"                             AS common_name ,
        COUNT(*)                                 AS total_1995 ,
        SUM(CASE WHEN "status" = 'Alive'                 THEN 1 ELSE 0 END) AS alive_1995 ,
        SUM(CASE WHEN "status" <> 'Alive'               THEN 1 ELSE 0 END) AS dead_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE TRIM(COALESCE("spc_latin",'')) <> ''
    GROUP BY latin_name , common_name
),

/* ---------- 2005 ---------- */
t2005 AS (
    SELECT
        UPPER("spc_latin")                       AS latin_name ,
        "spc_common"                             AS common_name ,
        COUNT(*)                                 AS total_2005 ,
        /* treat Excellent / Good / Poor as alive, the rest as dead */
        SUM(CASE WHEN "status" IN ('Excellent','Good','Poor')               THEN 1 ELSE 0 END) AS alive_2005 ,
        SUM(CASE WHEN "status" ILIKE '%dead%'  OR "status" = 'Stump'        THEN 1 ELSE 0 END) AS dead_2005
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2005
    WHERE TRIM(COALESCE("spc_latin",'')) <> ''
    GROUP BY latin_name , common_name
),

/* ---------- 2015 ---------- */
t2015 AS (
    SELECT
        UPPER("spc_latin")                       AS latin_name ,
        "spc_common"                             AS common_name ,
        COUNT(*)                                 AS total_2015 ,
        SUM(CASE WHEN "status" = 'Alive'                 THEN 1 ELSE 0 END) AS alive_2015 ,
        SUM(CASE WHEN "status" <> 'Alive'               THEN 1 ELSE 0 END) AS dead_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE TRIM(COALESCE("spc_latin",'')) <> ''
    GROUP BY latin_name , common_name
),

/* ---------- bring the three years together ---------- */
combined AS (
    SELECT
        COALESCE(t15.latin_name , t05.latin_name , t95.latin_name)   AS latin_name ,
        COALESCE(t15.common_name, t05.common_name, t95.common_name)  AS common_name ,

        /* 1995 */
        COALESCE(t95.total_1995 ,0)  AS total_1995 ,
        COALESCE(t95.alive_1995 ,0)  AS alive_1995 ,
        COALESCE(t95.dead_1995  ,0)  AS dead_1995 ,

        /* 2005 */
        COALESCE(t05.total_2005 ,0)  AS total_2005 ,
        COALESCE(t05.alive_2005 ,0)  AS alive_2005 ,
        COALESCE(t05.dead_2005  ,0)  AS dead_2005 ,

        /* 2015 */
        COALESCE(t15.total_2015 ,0)  AS total_2015 ,
        COALESCE(t15.alive_2015 ,0)  AS alive_2015 ,
        COALESCE(t15.dead_2015  ,0)  AS dead_2015
    FROM t2015  t15
    FULL OUTER JOIN t2005 t05 ON t05.latin_name = t15.latin_name
    FULL OUTER JOIN t1995 t95 ON t95.latin_name = COALESCE(t15.latin_name, t05.latin_name)
)

/* ---------- final selection ---------- */
SELECT
    latin_name ,
    common_name ,

    /* 1995 counts */
    total_1995 ,
    alive_1995 ,
    dead_1995 ,

    /* 2005 counts */
    total_2005 ,
    alive_2005 ,
    dead_2005 ,

    /* 2015 counts */
    total_2015 ,
    alive_2015 ,
    dead_2015 ,

    /* Growth 1995 → 2015 */
    (total_2015  - total_1995)  AS growth_total ,
    (alive_2015  - alive_1995)  AS growth_alive ,
    (dead_2015   - dead_1995)   AS growth_dead

FROM combined
ORDER BY growth_total DESC NULLS LAST
LIMIT 10;