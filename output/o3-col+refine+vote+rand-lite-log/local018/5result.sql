WITH top21 AS (                       -- #1 PCF-violation category in 2021
    SELECT co."pcf_violation_category" AS cat
    FROM   "collisions"  co
    JOIN   "case_ids"    ci ON ci."case_id" = co."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY cat
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
year_tot AS (                         -- total collisions in 2011 & 2021
    SELECT ci."db_year", COUNT(*) AS tot
    FROM   "collisions"  co
    JOIN   "case_ids"    ci ON ci."case_id" = co."case_id"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
),
cat_tot AS (                          -- collisions of that category in those years
    SELECT ci."db_year", COUNT(*) AS cat_cnt
    FROM   "collisions"  co
    JOIN   "case_ids"    ci ON ci."case_id" = co."case_id"
    JOIN   top21         tp ON tp.cat = co."pcf_violation_category"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
)
SELECT
    ROUND(
          100.0 * (SELECT cat_cnt FROM cat_tot  WHERE "db_year" = 2011) /
                  (SELECT tot     FROM year_tot WHERE "db_year" = 2011)
        - 100.0 * (SELECT cat_cnt FROM cat_tot  WHERE "db_year" = 2021) /
                  (SELECT tot     FROM year_tot WHERE "db_year" = 2021)
    , 4)  AS "percentage_point_decrease";