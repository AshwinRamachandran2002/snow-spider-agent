WITH top2 AS (
    SELECT 
        ci."db_year",
        c."pcf_violation_category",
        ROW_NUMBER() OVER (
            PARTITION BY ci."db_year"
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM "collisions" AS c
    JOIN "case_ids" AS ci
        ON ci."case_id" = c."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", c."pcf_violation_category"
),
pairs AS (
    SELECT
        "db_year",
        GROUP_CONCAT("pcf_violation_category", ' | ') AS top2_categories
    FROM top2
    WHERE rn <= 2
    GROUP BY "db_year"
),
pair_counts AS (
    SELECT
        top2_categories,
        COUNT(*) AS years_cnt
    FROM pairs
    GROUP BY top2_categories
)
SELECT p."db_year"
FROM pairs AS p
JOIN pair_counts AS pc
    ON pc.top2_categories = p.top2_categories
WHERE pc.years_cnt = 1
ORDER BY p."db_year";