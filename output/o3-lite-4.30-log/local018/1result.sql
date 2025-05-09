WITH top_category AS (
    SELECT c."pcf_violation_category" AS violation_category
    FROM   "collisions" c
    JOIN   "case_ids"  ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" = 2021
    GROUP  BY c."pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
year_stats AS (
    SELECT
        ci."db_year",
        COUNT(*) AS total_collisions,
        SUM(
            CASE
                WHEN c."pcf_violation_category" =
                     (SELECT violation_category FROM top_category)
                THEN 1 ELSE 0
            END
        ) AS cat_collisions
    FROM   "collisions" c
    JOIN   "case_ids"  ci ON ci."case_id" = c."case_id"
    WHERE  ci."db_year" IN (2011, 2021)
    GROUP  BY ci."db_year"
),
shares AS (
    SELECT
        "db_year",
        100.0 * cat_collisions / total_collisions AS share_pct
    FROM   year_stats
)
SELECT
    (SELECT violation_category FROM top_category)                                           AS violation_category,
    ROUND(
        (SELECT share_pct FROM shares WHERE "db_year" = 2011) -
        (SELECT share_pct FROM shares WHERE "db_year" = 2021)
    , 4)                                                                                    AS percentage_point_decrease;