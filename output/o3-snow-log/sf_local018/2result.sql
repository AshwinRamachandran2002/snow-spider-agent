/*  Step-by-step
    1) Find the most common “primary-collision-factor violation category” in 2021.
    2) For that single category, get its collision count and percentage share
       of ALL crashes in 2011 and 2021.
    3) Return the two shares plus the 2011-to-2021 percentage-point decrease.
*/
WITH top_2021_category AS (          -- step 1
    SELECT "pcf_violation_category" AS cat
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE  SUBSTR("collision_date",1,4) = '2021'
    GROUP  BY "pcf_violation_category"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),

year_totals AS (                     -- total crashes per year (2011, 2021)
    SELECT  SUBSTR("collision_date",1,4) AS yr,
            COUNT(*)                     AS total_cnt
    FROM    "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE   SUBSTR("collision_date",1,4) IN ('2011','2021')
    GROUP   BY yr
),

year_cat_counts AS (                 -- crashes of the top category per year
    SELECT  SUBSTR(c."collision_date",1,4) AS yr,
            COUNT(*)                       AS cat_cnt
    FROM    "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"  c
    JOIN    top_2021_category  tc
            ON c."pcf_violation_category" = tc.cat
    WHERE   SUBSTR(c."collision_date",1,4) IN ('2011','2021')
    GROUP   BY yr
),

year_shares AS (                     -- percentage share of all crashes
    SELECT  y.yr,
            ROUND( y.cat_cnt * 100.0 / t.total_cnt , 2) AS pct_share
    FROM    year_cat_counts y
    JOIN    year_totals     t  ON y.yr = t.yr
)

SELECT  MAX(CASE WHEN yr = '2021' THEN pct_share END) AS share_2021,
        MAX(CASE WHEN yr = '2011' THEN pct_share END) AS share_2011,
        /* 2011 share minus 2021 share = percentage-point decrease */
        ROUND( MAX(CASE WHEN yr = '2011' THEN pct_share END)
             - MAX(CASE WHEN yr = '2021' THEN pct_share END), 2) 
        AS percentage_point_decrease
FROM    year_shares;