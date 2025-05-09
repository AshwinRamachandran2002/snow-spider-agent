WITH top21 AS (  -- most common PCF-violation category in 2021
    SELECT c."pcf_violation_category"
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS  c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS    y
           ON c."case_id" = y."case_id"
    WHERE  y."db_year" = 2021
      AND  c."pcf_violation_category" IS NOT NULL
      AND  c."pcf_violation_category" <> ''
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT 1
), totals AS (     -- total crashes each year
    SELECT
        (SELECT COUNT(*) 
         FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c21
         JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS   y21
           ON c21."case_id" = y21."case_id"
         WHERE y21."db_year" = 2021) AS tot_2021,
        (SELECT COUNT(*) 
         FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c11
         JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS   y11
           ON c11."case_id" = y11."case_id"
         WHERE y11."db_year" = 2011) AS tot_2011
)
SELECT
    t."pcf_violation_category",
    -- share in 2021
    SUM(CASE WHEN y."db_year" = 2021 THEN 1 END)::FLOAT / tot.tot_2021 * 100  AS "share_2021_pct",
    -- share in 2011
    SUM(CASE WHEN y."db_year" = 2011 THEN 1 END)::FLOAT / tot.tot_2011 * 100  AS "share_2011_pct",
    -- percentage-point change (2021 minus 2011, will be negative if it decreased)
    (SUM(CASE WHEN y."db_year" = 2021 THEN 1 END)::FLOAT / tot.tot_2021 * 100) -
    (SUM(CASE WHEN y."db_year" = 2011 THEN 1 END)::FLOAT / tot.tot_2011 * 100)      AS "percentage_point_change_2021_vs_2011"
FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS  c
JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.CASE_IDS    y
       ON c."case_id" = y."case_id"
JOIN   top21 t
       ON c."pcf_violation_category" = t."pcf_violation_category"
CROSS JOIN totals tot
WHERE  y."db_year" IN (2011, 2021)
GROUP  BY t."pcf_violation_category", tot.tot_2021, tot.tot_2011;