-- number of actors who never had a gap of 4 or more consecutive years
SELECT COUNT(*) AS actor_count
FROM (
    -- compute the largest year-to-year gap for every actor
    SELECT
        gaps."PID",
        MAX(COALESCE(gaps.gap,0)) AS max_gap
    FROM (
        -- year-to-year differences per actor
        SELECT
            ay."PID",
            ay."year"
            - LAG(ay."year") OVER (PARTITION BY ay."PID" ORDER BY ay."year") AS gap
        FROM (
            -- unique (actor, year) pairs
            SELECT DISTINCT
                TRIM(mc."PID")              AS "PID",
                CAST(m."year" AS INTEGER)   AS "year"
            FROM "M_Cast"  mc
            JOIN "Movie"   m ON m."MID" = mc."MID"
            WHERE m."year" <> ''           -- ignore missing years
        ) ay
    ) gaps
    GROUP BY gaps."PID"
) actor_max_gap
WHERE actor_max_gap.max_gap <= 3;