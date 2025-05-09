WITH actor_years AS (          -- every actor with each distinct credit year
    SELECT
        mc."PID",
        CAST(m."year" AS INTEGER) AS yr
    FROM "M_Cast" mc
    JOIN "Movie" m ON m."MID" = mc."MID"
    GROUP BY mc."PID", yr
), 
gaps AS (                      -- gap between successive credited years
    SELECT
        PID,
        yr,
        LEAD(yr) OVER (PARTITION BY PID ORDER BY yr) AS next_yr
    FROM actor_years
), 
bad_actors AS (                -- actors who ever have a gap larger than 3 years
    SELECT DISTINCT PID
    FROM gaps
    WHERE next_yr IS NOT NULL
      AND next_yr - yr > 4     -- a difference of 5 or more → 4‑year span with no credit
), 
all_actors AS (                -- every actor appearing in at least one movie
    SELECT DISTINCT "PID"
    FROM "M_Cast"
)
SELECT COUNT(*) AS actor_count  -- requested result
FROM all_actors
WHERE PID NOT IN (SELECT PID FROM bad_actors);