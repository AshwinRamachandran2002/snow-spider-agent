WITH cause_counts AS (
    SELECT ci."db_year",
           co."pcf_violation_category",
           COUNT(*) AS cnt
    FROM "collisions" AS co
    JOIN "case_ids"  AS ci ON ci."case_id" = co."case_id"
    WHERE co."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", co."pcf_violation_category"
),
ranked AS (
    SELECT db_year,
           pcf_violation_category,
           ROW_NUMBER() OVER (PARTITION BY db_year ORDER BY cnt DESC) AS rn
    FROM cause_counts
),
top_two AS (
    SELECT db_year,
           MAX(CASE WHEN rn = 1 THEN pcf_violation_category END) AS top1,
           MAX(CASE WHEN rn = 2 THEN pcf_violation_category END) AS top2
    FROM ranked
    WHERE rn <= 2
    GROUP BY db_year
    HAVING top1 IS NOT NULL AND top2 IS NOT NULL
),
pair_freq AS (
    SELECT top1 || '|' || top2 AS pair,
           COUNT(*)            AS times
    FROM top_two
    GROUP BY pair
)
SELECT t.db_year AS year
FROM top_two  AS t
JOIN pair_freq AS f ON f.pair = t.top1 || '|' || t.top2
WHERE f.times = 1
ORDER BY year;