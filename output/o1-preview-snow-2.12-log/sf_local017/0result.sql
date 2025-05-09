WITH overall_top_causes AS (
    SELECT "primary_collision_factor"
    FROM (
        SELECT "primary_collision_factor", COUNT(*) AS total_count
        FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
        WHERE "primary_collision_factor" IS NOT NULL AND "primary_collision_factor" != ''
        GROUP BY "primary_collision_factor"
    ) t
    ORDER BY total_count DESC NULLS LAST
    LIMIT 2
),
yearly_top_causes AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE("collision_date", 'YYYY-MM-DD')) AS "year",
        "primary_collision_factor",
        COUNT(*) AS collision_count,
        DENSE_RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM TO_DATE("collision_date", 'YYYY-MM-DD')) 
            ORDER BY COUNT(*) DESC NULLS LAST
        ) AS cause_rank
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
    WHERE "primary_collision_factor" IS NOT NULL AND "primary_collision_factor" != ''
    GROUP BY 
        EXTRACT(YEAR FROM TO_DATE("collision_date", 'YYYY-MM-DD')), 
        "primary_collision_factor"
)
SELECT DISTINCT "year"
FROM (
    SELECT 
        ytc."year",
        MIN(CASE WHEN cause_rank = 1 THEN ytc."primary_collision_factor" END) AS cause1,
        MIN(CASE WHEN cause_rank = 2 THEN ytc."primary_collision_factor" END) AS cause2
    FROM yearly_top_causes ytc
    WHERE cause_rank <= 2
    GROUP BY ytc."year"
) top_causes
WHERE NOT (
    (cause1 = 'vehicle code violation' AND cause2 = 'unknown') OR
    (cause1 = 'unknown' AND cause2 = 'vehicle code violation')
)
ORDER BY "year";