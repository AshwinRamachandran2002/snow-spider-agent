WITH actor_years AS (
    SELECT DISTINCT
           TRIM(c."PID")                  AS PID,
           CAST(m."year" AS INTEGER)      AS yr
    FROM   "M_Cast"  c
    JOIN   "Movie"   m ON m."MID" = c."MID"
    WHERE  m."year" IS NOT NULL
      AND  CAST(m."year" AS INTEGER) > 0
),
gaps AS (
    SELECT
        PID,
        yr,
        LAG(yr) OVER (PARTITION BY PID ORDER BY yr) AS prev_yr
    FROM actor_years
),
max_gap AS (
    SELECT
        PID,
        MAX( (yr - prev_yr) - 1 ) AS max_gap
    FROM gaps
    WHERE prev_yr IS NOT NULL
    GROUP BY PID
),
all_actors AS (
    SELECT DISTINCT PID FROM actor_years
)
SELECT COUNT(*) AS actor_count
FROM   all_actors  a
LEFT   JOIN max_gap g USING (PID)
WHERE  COALESCE(g.max_gap, 0) <= 3;