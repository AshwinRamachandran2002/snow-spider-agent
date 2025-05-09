WITH year_category_counts AS (
    SELECT
        ci.db_year AS year,
        c.pcf_violation_category AS category
    FROM collisions AS c
    JOIN case_ids  AS ci ON ci.case_id = c.case_id
    WHERE c.pcf_violation_category IS NOT NULL
),
ranked AS (
    SELECT
        year,
        category,
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY COUNT(*) DESC, category
        ) AS rn
    FROM year_category_counts
    GROUP BY year, category
),
top_two AS (
    SELECT
        year,
        MAX(CASE WHEN rn = 1 THEN category END) || '|' ||
        MAX(CASE WHEN rn = 2 THEN category END) AS top2_categories
    FROM ranked
    WHERE rn <= 2
    GROUP BY year
    HAVING COUNT(*) = 2        -- ensure exactly two distinct top causes
),
combo_stats AS (
    SELECT
        top2_categories,
        COUNT(*) AS years_with_this_combo
    FROM top_two
    GROUP BY top2_categories
)
SELECT
    year
FROM top_two
WHERE top2_categories IN (
    SELECT top2_categories
    FROM combo_stats
    WHERE years_with_this_combo = 1      -- unique combination
)
ORDER BY year;