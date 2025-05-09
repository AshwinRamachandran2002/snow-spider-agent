WITH actor_years AS (          -- every actor’s distinct appearance years
    SELECT 
        mc."PID",
        CAST(m."year" AS INTEGER) AS yr
    FROM "M_Cast" mc
    JOIN "Movie"  m ON mc."MID" = m."MID"
    GROUP BY mc."PID", yr
),
ordered AS (                   -- next appearance year for each actor
    SELECT
        "PID",
        yr,
        LEAD(yr) OVER (PARTITION BY "PID" ORDER BY yr) AS next_yr
    FROM actor_years
),
actor_with_long_gap AS (       -- actors who have a gap ≥ 4 missing years (diff > 4)
    SELECT DISTINCT "PID"
    FROM ordered
    WHERE next_yr IS NOT NULL
      AND next_yr - yr > 4
)
SELECT COUNT(DISTINCT "PID") AS actor_count
FROM actor_years
WHERE "PID" NOT IN (SELECT "PID" FROM actor_with_long_gap);