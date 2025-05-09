WITH top_cat AS (   -- 1. Find the most common PCF-violation category in 2021
    SELECT c."pcf_violation_category"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS  y
           ON c."case_id" = y."case_id"
    WHERE  y."db_year" = 2021
    GROUP BY c."pcf_violation_category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
year_counts AS (     -- 2. 2011 and 2021 counts for that category + totals
    /* ---- 2011 ---- */
    SELECT
        2011                                         AS "yr",
        COUNT(*)::FLOAT                              AS "cat_cnt",
        (SELECT COUNT(*)
         FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
         WHERE "collision_date" ILIKE '2011-%')::FLOAT AS "tot_cnt"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
    JOIN   top_cat t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  c."collision_date" ILIKE '2011-%'
    
    UNION ALL
    
    /* ---- 2021 ---- */
    SELECT
        2021                                         AS "yr",
        COUNT(*)::FLOAT                              AS "cat_cnt",
        (SELECT COUNT(*)
         FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS  c2
         JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS     y2
                ON c2."case_id" = y2."case_id"
         WHERE  y2."db_year" = 2021)::FLOAT          AS "tot_cnt"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS  c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS     y
           ON c."case_id" = y."case_id"
    JOIN   top_cat t
           ON c."pcf_violation_category" = t."pcf_violation_category"
    WHERE  y."db_year" = 2021
),
shares AS (          -- 3. Convert to shares (%)
    SELECT
        "yr",
        ("cat_cnt" / "tot_cnt") * 100.0 AS "share_pct"
    FROM year_counts
),
answer AS (          -- 4. %-point decrease = 2011 share – 2021 share
    SELECT
        MAX(CASE WHEN "yr" = 2011 THEN "share_pct" END) -
        MAX(CASE WHEN "yr" = 2021 THEN "share_pct" END) AS "pct_point_decrease"
    FROM shares
)
SELECT "pct_point_decrease"
FROM   answer;