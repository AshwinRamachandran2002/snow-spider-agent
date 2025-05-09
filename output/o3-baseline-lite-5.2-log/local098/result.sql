WITH ActorYears AS (          -- every actor‑year pair
    SELECT DISTINCT
           mc."PID",
           CAST(m."year" AS INTEGER) AS yr
    FROM "M_Cast" mc
    JOIN "Movie" m ON mc."MID" = m."MID"
),
Ordered AS (                  -- years in order per actor, with previous year
    SELECT
        "PID",
        yr,
        LAG(yr) OVER (PARTITION BY "PID" ORDER BY yr) AS prev_yr
    FROM ActorYears
),
GapSize AS (                  -- biggest distance between successive credits
    SELECT
        "PID",
        MAX(yr - prev_yr) AS max_gap
    FROM Ordered
    GROUP BY "PID"
)
SELECT COUNT(*)               -- actors whose longest gap is ≤ 3 years
FROM GapSize
WHERE COALESCE(max_gap,0) < 5;