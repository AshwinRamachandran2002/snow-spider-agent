WITH overall_top2 AS (               -- the two most‑frequent causes overall
    SELECT c."pcf_violation_category" AS cause
    FROM   "case_ids"  AS ci
    JOIN   "collisions" AS c USING ("case_id")
    GROUP  BY cause
    ORDER  BY COUNT(*) DESC
    LIMIT 2
),
per_year_rank AS (                   -- rank causes within each year
    SELECT
        ci."db_year"                         AS yr,
        c."pcf_violation_category"           AS cause,
        DENSE_RANK() OVER (PARTITION BY ci."db_year"
                           ORDER BY COUNT(*) DESC) AS rk
    FROM   "case_ids"  AS ci
    JOIN   "collisions" AS c USING ("case_id")
    GROUP  BY ci."db_year", c."pcf_violation_category"
),
per_year_top2 AS (                   -- keep only each year’s Top‑2 causes
    SELECT yr, cause
    FROM   per_year_rank
    WHERE  rk <= 2
)
SELECT yr AS "year_with_different_top2_causes"
FROM   per_year_top2
GROUP  BY yr
HAVING SUM(CASE WHEN cause IN (SELECT cause FROM overall_top2) THEN 1 ELSE 0 END) < 2
ORDER  BY yr;