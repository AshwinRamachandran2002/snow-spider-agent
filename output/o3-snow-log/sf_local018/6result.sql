WITH
/* 1) Count 2021 collisions by PCF category and find the top (most common) category */
collisions_2021 AS (
    SELECT
        c."pcf_violation_category",
        COUNT(*) AS "cnt_2021"
    FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"      c
    JOIN "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."CASE_IDS"        y
          ON c."case_id" = y."case_id"
    WHERE y."db_year" = 2021
    GROUP BY c."pcf_violation_category"
),  
top_category AS (
    SELECT "pcf_violation_category"
    FROM   collisions_2021
    ORDER  BY "cnt_2021" DESC NULLS LAST
    LIMIT 1                           -- the most common PCF category in 2021
),

/* 2) Totals and category-specific counts for 2021 */
tot_2021 AS (
    SELECT COUNT(*) AS "total_2021"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS" c
    JOIN   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."CASE_IDS"   y
           ON c."case_id" = y."case_id"
    WHERE  y."db_year" = 2021
),
cat_2021 AS (
    SELECT COUNT(*) AS "cat_2021"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS" c
    JOIN   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."CASE_IDS"   y
           ON c."case_id" = y."case_id"
    JOIN   top_category t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  y."db_year" = 2021
),

/* 3) Totals and category-specific counts for 2011 */
tot_2011 AS (
    SELECT COUNT(*) AS "total_2011"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE  "collision_date" ILIKE '2011%'        -- calendar year 2011
),
cat_2011 AS (
    SELECT COUNT(*) AS "cat_2011"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS" c
    JOIN   top_category t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  c."collision_date" ILIKE '2011%'
)

/* 4) Put everything together and calculate the percentage-point change */
SELECT
    t."pcf_violation_category"                                            AS "pcf_violation_category",
    ROUND(c21."cat_2021"::FLOAT / tot21."total_2021" * 100, 4)            AS "share_2021_pct",
    ROUND(c11."cat_2011"::FLOAT / tot11."total_2011" * 100, 4)            AS "share_2011_pct",
    ROUND( (c11."cat_2011"::FLOAT / tot11."total_2011" * 100)             -- decrease = 2011 minus 2021
         - (c21."cat_2021"::FLOAT / tot21."total_2021" * 100), 4)         AS "percentage_point_decrease"
FROM
    top_category  t
    CROSS JOIN cat_2021 c21
    CROSS JOIN tot_2021 tot21
    CROSS JOIN cat_2011 c11
    CROSS JOIN tot_2011 tot11;