WITH global_top AS (
    SELECT c."pcf_violation_category"
    FROM "collisions" c
    JOIN "case_ids" ci ON ci."case_id" = c."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY c."pcf_violation_category"
    ORDER BY COUNT(*) DESC
    LIMIT 2
),
yearly_rank AS (
    SELECT
        ci."db_year"                AS year,
        c."pcf_violation_category",
        ROW_NUMBER() OVER (
            PARTITION BY ci."db_year"
            ORDER BY COUNT(*) DESC
        )                           AS rn
    FROM "collisions" c
    JOIN "case_ids"  ci ON ci."case_id" = c."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", c."pcf_violation_category"
),
year_top2 AS (
    SELECT year, "pcf_violation_category"
    FROM   yearly_rank
    WHERE  rn <= 2
)
SELECT year
FROM   year_top2
GROUP  BY year
HAVING SUM(
           CASE
               WHEN "pcf_violation_category" IN (SELECT "pcf_violation_category" FROM global_top)
               THEN 1 ELSE 0
           END
       ) < 2
ORDER BY year;