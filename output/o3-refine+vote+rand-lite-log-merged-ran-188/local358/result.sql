WITH age_counts AS (
    SELECT
        CASE
            WHEN age BETWEEN 20 AND 29 THEN '20s'
            WHEN age BETWEEN 30 AND 39 THEN '30s'
            WHEN age BETWEEN 40 AND 49 THEN '40s'
            WHEN age BETWEEN 50 AND 59 THEN '50s'
            ELSE 'others'
        END AS age_category,
        COUNT(*) AS user_count
    FROM (
        SELECT
            "user_id",
            (CAST(strftime('%Y%m%d','now') AS INTEGER) -
             CAST(strftime('%Y%m%d',"birth_date") AS INTEGER)) / 10000 AS age
        FROM "mst_users"
        WHERE "birth_date" IS NOT NULL
    )
    GROUP BY age_category
),
categories AS (
    SELECT '20s'   AS age_category UNION ALL
    SELECT '30s'   UNION ALL
    SELECT '40s'   UNION ALL
    SELECT '50s'   UNION ALL
    SELECT 'others'
)
SELECT
    c.age_category,
    COALESCE(a.user_count, 0) AS user_count
FROM categories c
LEFT JOIN age_counts a
       ON a.age_category = c.age_category
ORDER BY
    CASE c.age_category
        WHEN '20s'   THEN 1
        WHEN '30s'   THEN 2
        WHEN '40s'   THEN 3
        WHEN '50s'   THEN 4
        ELSE 5
    END;