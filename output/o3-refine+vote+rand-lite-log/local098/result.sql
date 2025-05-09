WITH actor_years AS (
    -- every distinct year in which an actor appeared
    SELECT
        mc."PID"       AS pid,
        CAST(m."year" AS INTEGER) AS yr
    FROM "M_Cast"   mc
    JOIN "Movie"    m  ON m."MID" = mc."MID"
    GROUP BY mc."PID", m."year"
),
ordered AS (
    -- order the years for each actor and get previous year
    SELECT
        pid,
        yr,
        LAG(yr) OVER (PARTITION BY pid ORDER BY yr) AS prev_yr
    FROM actor_years
),
gaps AS (
    -- difference between consecutive appearance years
    SELECT
        pid,
        COALESCE(yr - prev_yr, 0) AS diff
    FROM ordered
),
violations AS (
    -- actors who have a gap of 4 or more consecutive missing years
    SELECT DISTINCT pid
    FROM gaps
    WHERE diff >= 5          -- 5‑year jump ⇒ 4 full vacant years
),
qualified_actors AS (
    -- actors with no such violating gap
    SELECT DISTINCT pid
    FROM actor_years
    WHERE pid NOT IN (SELECT pid FROM violations)
)
SELECT COUNT(*) AS actor_count
FROM qualified_actors;