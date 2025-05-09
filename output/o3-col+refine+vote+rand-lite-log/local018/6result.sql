WITH top_cat AS (                               -- 1) most frequent PCF category in 2021
    SELECT c."pcf_violation_category" AS cat
    FROM   "collisions" c
    JOIN   "case_ids"  ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
year_totals AS (                                -- 2) total collisions in 2011 & 2021
    SELECT ci."db_year" AS yr,
           COUNT(*)     AS tot
    FROM   "collisions" c
    JOIN   "case_ids"  ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
),
cat_totals AS (                                 -- 3) collisions of that top category
    SELECT ci."db_year" AS yr,
           COUNT(*)     AS tot
    FROM   "collisions" c
    JOIN   "case_ids"  ci ON ci."case_id" = c."case_id", top_cat
    WHERE  ci."db_year" IN (2011, 2021)
      AND  c."pcf_violation_category" = top_cat.cat
    GROUP  BY ci."db_year"
),
shares AS (                                     -- 4) share (%) of that category each year
    SELECT y.yr,
           100.0 * COALESCE(c.tot,0) / y.tot AS pct
    FROM   year_totals y
    LEFT   JOIN cat_totals c ON c.yr = y.yr
)
SELECT ROUND(
         (SELECT pct FROM shares WHERE yr = 2011) -
         (SELECT pct FROM shares WHERE yr = 2021)
       , 4) AS percentage_point_decrease;