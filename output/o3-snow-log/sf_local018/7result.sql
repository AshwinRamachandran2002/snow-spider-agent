/*  Percentage-point change in share of crashes for the most-common
    2021 PCF-violation category ( 2021 share  –  2011 share )          */
WITH top_2021_cat AS (         -- 1. find the most frequent category in 2021
    SELECT c."pcf_violation_category"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    ci
           ON c."case_id" = ci."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),
yearly_stats AS (              -- 2. counts for that category and for all crashes
    /* 2021 */
    SELECT
        '2021'                                       AS "yr",
        COUNT(CASE WHEN t."pcf_violation_category" IS NOT NULL THEN 1 END) 
                                                     AS "cat_cnt",
        COUNT(*)                                     AS "total_cnt"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    ci
           ON c."case_id" = ci."case_id"
    LEFT JOIN top_2021_cat t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  ci."db_year" = 2021

    UNION ALL
    /* 2011 */
    SELECT
        '2011'                                       AS "yr",
        COUNT(CASE WHEN t."pcf_violation_category" IS NOT NULL THEN 1 END) 
                                                     AS "cat_cnt",
        COUNT(*)                                     AS "total_cnt"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
    LEFT  JOIN top_2021_cat t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  c."collision_date" LIKE '2011-%'
),
shares AS (                    -- 3. convert to percentages
    SELECT
        "yr",
        "cat_cnt" * 100.0 / "total_cnt" AS "share_pct"
    FROM   yearly_stats
)
-- 4. percentage-point change (2021 – 2011)
SELECT
    MAX(CASE WHEN "yr" = '2021' THEN "share_pct" END) -
    MAX(CASE WHEN "yr" = '2011' THEN "share_pct" END)  AS "share_pct_point_change_2021_minus_2011"
FROM   shares;