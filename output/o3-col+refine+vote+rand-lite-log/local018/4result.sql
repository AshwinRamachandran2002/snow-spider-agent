WITH top_cat AS (
    -- 1. What violation category was most common in 2021?
    SELECT c."pcf_violation_category" AS cat
    FROM   "collisions" AS c
    JOIN   "case_ids"  AS ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
yearly_pct AS (
    -- 2. Share of that category in 2011 vs 2021
    SELECT ci."db_year",
           100.0 * SUM(CASE WHEN c."pcf_violation_category" = (SELECT cat FROM top_cat)
                            THEN 1 ELSE 0 END) / COUNT(*) AS pct
    FROM   "collisions" AS c
    JOIN   "case_ids"  AS ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
)
-- 3. Percentage-point decrease from 2011 to 2021
SELECT ROUND(
         (SELECT pct FROM yearly_pct WHERE "db_year" = 2011) -
         (SELECT pct FROM yearly_pct WHERE "db_year" = 2021)
       , 4
       ) AS "percentage_point_decrease";