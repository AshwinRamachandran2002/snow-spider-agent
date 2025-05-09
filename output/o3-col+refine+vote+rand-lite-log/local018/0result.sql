WITH top_cat AS (
    SELECT col."pcf_violation_category" AS cat
    FROM   "collisions" AS col
    JOIN   "case_ids"   AS ci
           ON col."case_id" = ci."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY col."pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
shares AS (
    SELECT ci."db_year" AS yr,
           100.0 * SUM(CASE
                           WHEN col."pcf_violation_category" = (SELECT cat FROM top_cat)
                           THEN 1 ELSE 0 END
                      ) / COUNT(*)                    AS pct
    FROM   "collisions" AS col
    JOIN   "case_ids"   AS ci
           ON col."case_id" = ci."case_id"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
)
SELECT ROUND(
         MAX(CASE WHEN yr = 2011 THEN pct END)
       - MAX(CASE WHEN yr = 2021 THEN pct END)
       , 4) AS "percentage_points_decrease"
FROM   shares;