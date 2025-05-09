WITH actor_years AS (
    SELECT 
        TRIM(c."PID")                   AS "PID",
        CAST(m."year" AS INTEGER)       AS yr
    FROM   "M_Cast"  AS c
    JOIN   "Movie"   AS m ON m."MID" = c."MID"
    GROUP  BY "PID", yr                       -- one row per actor-year
),
gaps AS (
    SELECT
        ay."PID",
        COALESCE(ay.yr - LAG(ay.yr) OVER (PARTITION BY ay."PID" ORDER BY ay.yr),0) 
                                                AS gap_size
    FROM actor_years ay
),
max_gap AS (
    SELECT 
        "PID",
        MAX(gap_size) AS largest_gap
    FROM   gaps
    GROUP  BY "PID"
)
SELECT COUNT(*) AS actors_without_four_year_gap
FROM   max_gap
WHERE  largest_gap <= 4;