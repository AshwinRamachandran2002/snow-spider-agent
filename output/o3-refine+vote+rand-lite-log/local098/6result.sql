WITH actor_years AS (
    -- every distinct (actor , movie year) pair
    SELECT DISTINCT 
           MC."PID"                                   AS pid,
           CAST(M."year" AS INTEGER)                  AS yr
    FROM   "M_Cast" MC
    JOIN   "Movie"  M  ON MC."MID" = M."MID"
),
year_gaps AS (
    -- difference between consecutive credited years for each actor
    SELECT  pid,
            yr,
            yr - LAG(yr) OVER (PARTITION BY pid ORDER BY yr) AS diff
    FROM    actor_years
),
max_gap_per_actor AS (
    -- largest year‑to‑year jump (i.e., longest gap + 1) for each actor
    SELECT  pid,
            COALESCE(MAX(diff),0) AS max_diff
    FROM    year_gaps
    GROUP BY pid
)
-- actors whose longest gap is at most 3 empty years (diff ≤ 4)
SELECT COUNT(*)
FROM   max_gap_per_actor
WHERE  max_diff <= 4;