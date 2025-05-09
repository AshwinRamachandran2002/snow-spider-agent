WITH actor_years AS (
    -- distinct years in which each actor (PID) appeared
    SELECT 
        mc."PID",
        CAST(mo."year" AS INTEGER) AS yr
    FROM "M_Cast"   AS mc
    JOIN "Movie"    AS mo ON mo."MID" = mc."MID"
    GROUP BY mc."PID", yr
),
gaps AS (
    -- difference between consecutive appearance years
    SELECT
        ay."PID",
        ay.yr,
        ay.yr - LAG(ay.yr) OVER (PARTITION BY ay."PID" ORDER BY ay.yr) AS diff
    FROM actor_years ay
),
qualified_actors AS (
    -- keep actors whose largest gap is at most 4 years (i.e., ≤ 3 empty years)
    SELECT 
        "PID"
    FROM gaps
    GROUP BY "PID"
    HAVING MAX(COALESCE(diff,0)) <= 4
)
-- final answer: how many such actors
SELECT COUNT(*) AS num_actors_without_4_year_gap
FROM qualified_actors;