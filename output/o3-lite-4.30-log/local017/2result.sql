WITH ranked AS (
    SELECT 
        y."db_year"               AS year,
        c."pcf_violation_category",
        COUNT(*)                  AS freq,
        ROW_NUMBER() OVER (
            PARTITION BY y."db_year"
            ORDER BY COUNT(*) DESC
        )                         AS rnk
    FROM "collisions" c
    JOIN "case_ids"  y ON c."case_id" = y."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY y."db_year", c."pcf_violation_category"
),
top_two AS (
    SELECT
        year,
        MAX(CASE WHEN rnk = 1 THEN "pcf_violation_category" END) AS cause1,
        MAX(CASE WHEN rnk = 2 THEN "pcf_violation_category" END) AS cause2
    FROM ranked
    WHERE rnk <= 2
    GROUP BY year
),
combo_count AS (
    SELECT
        (cause1 || ' | ' || cause2) AS combo,
        COUNT(*)                    AS yrs
    FROM top_two
    GROUP BY combo
)
SELECT t.year
FROM   top_two     t
JOIN   combo_count cc ON (t.cause1 || ' | ' || t.cause2) = cc.combo
WHERE  cc.yrs = 1
ORDER BY t.year;