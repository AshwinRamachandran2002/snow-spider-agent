WITH top_cat_2021 AS (          -- most common PCF violation category in 2021
    SELECT "pcf_violation_category" AS top_cat
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"
    WHERE "collision_date" LIKE '2021-%'
    GROUP BY "pcf_violation_category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
year_totals AS (                -- total collisions in each target year
    SELECT
        TO_NUMBER(SUBSTR("collision_date",1,4)) AS yr,
        COUNT(*)                                AS total_cnt
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"
    WHERE "collision_date" LIKE '2011-%'
       OR "collision_date" LIKE '2021-%'
    GROUP BY TO_NUMBER(SUBSTR("collision_date",1,4))
),
year_cat AS (                   -- collisions for that top category in each year
    SELECT
        TO_NUMBER(SUBSTR(c."collision_date",1,4)) AS yr,
        COUNT(*)                                  AS cat_cnt
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
    JOIN top_cat_2021 t
      ON c."pcf_violation_category" = t.top_cat
    WHERE c."collision_date" LIKE '2011-%'
       OR c."collision_date" LIKE '2021-%'
    GROUP BY TO_NUMBER(SUBSTR(c."collision_date",1,4))
),
shares AS (                     -- share (%) of that category in each year
    SELECT
        y.yr,
        y.cat_cnt * 100.0 / t.total_cnt AS share_pct
    FROM year_cat y
    JOIN year_totals t ON y.yr = t.yr
)
SELECT
    ROUND(
        MAX(CASE WHEN yr = 2011 THEN share_pct END)   -- 2011 share
      - MAX(CASE WHEN yr = 2021 THEN share_pct END)   -- minus 2021 share
    , 4) AS "share_decrease_pct_points"
FROM shares;