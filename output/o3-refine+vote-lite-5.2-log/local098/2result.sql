WITH actor_years AS (
    -- distinct years each actor appeared in a movie
    SELECT mc."PID",
           CAST(m."year" AS INTEGER) AS yr
    FROM "M_Cast"  mc
    JOIN "Movie"   m  ON mc."MID" = m."MID"
    WHERE m."year" <> ''                     -- keep only rows with a year value
    GROUP BY mc."PID", yr
),
gap_check AS (
    -- for every consecutive pair of years per actor, see if the gap is 4+ years
    SELECT
        PID,
        CASE
            WHEN LEAD(yr) OVER (PARTITION BY PID ORDER BY yr) - yr > 4
            THEN 1 ELSE 0
        END AS has_big_gap
    FROM actor_years
),
actors_with_big_gap AS (
    SELECT DISTINCT PID
    FROM gap_check
    WHERE has_big_gap = 1                    -- at least one 4‑year (or longer) gap
),
qualified_actors AS (
    -- actors whose maximum gap is ≤ 3 years
    SELECT DISTINCT PID
    FROM actor_years
    EXCEPT
    SELECT PID FROM actors_with_big_gap
)
SELECT COUNT(*) AS num_actors_without_4year_gap
FROM qualified_actors;