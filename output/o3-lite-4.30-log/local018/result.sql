WITH top21 AS (  /* most frequent violation category in 2021 */
    SELECT c."pcf_violation_category" AS category
    FROM   "collisions" c
    JOIN   "case_ids"    y ON c."case_id" = y."case_id"
    WHERE  y."db_year" = 2021
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
total_per_year AS (          /* total crashes in 2011 & 2021 */
    SELECT y."db_year",
           COUNT(*) AS total
    FROM   "collisions" c
    JOIN   "case_ids"  y ON c."case_id" = y."case_id"
    WHERE  y."db_year" IN (2011, 2021)
    GROUP  BY y."db_year"
),
cat_per_year AS (            /* crashes of that category in 2011 & 2021 */
    SELECT y."db_year",
           COUNT(*) AS cat_cnt
    FROM   "collisions" c
    JOIN   "case_ids"  y ON c."case_id" = y."case_id"
    JOIN   top21       t ON c."pcf_violation_category" = t.category
    WHERE  y."db_year" IN (2011, 2021)
    GROUP  BY y."db_year"
),
shares AS (                  /* percentage share in each year */
    SELECT cp."db_year",
           100.0 * cp.cat_cnt / tp.total AS pct
    FROM   cat_per_year  cp
    JOIN   total_per_year tp ON cp."db_year" = tp."db_year"
)
SELECT
    (SELECT category FROM top21)                                        AS violation_category,
    ROUND( (SELECT pct FROM shares WHERE db_year = 2011) -
           (SELECT pct FROM shares WHERE db_year = 2021), 4 )           AS percentage_point_decrease
;