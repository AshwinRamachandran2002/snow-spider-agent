WITH overall_top2 AS (
    SELECT 
        c."pcf_violation_category" AS cause
    FROM "collisions" AS c
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY cause
    ORDER BY COUNT(*) DESC
    LIMIT 2
),
yearly_counts AS (
    SELECT
        ci."db_year"              AS yr,
        c."pcf_violation_category" AS cause,
        COUNT(*)                  AS cnt
    FROM "collisions" AS c
    JOIN "case_ids"  AS ci
      ON ci."case_id" = c."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY yr, cause
),
ranked_causes AS (
    SELECT
        yr,
        cause,
        ROW_NUMBER() OVER (PARTITION BY yr ORDER BY cnt DESC) AS rn
    FROM yearly_counts
),
top2_per_year AS (
    SELECT
        yr,
        cause
    FROM ranked_causes
    WHERE rn <= 2
)
SELECT DISTINCT
    yr AS "year_with_different_top2"
FROM top2_per_year
WHERE cause NOT IN (SELECT cause FROM overall_top2)
ORDER BY yr;