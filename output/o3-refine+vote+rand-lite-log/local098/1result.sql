WITH actor_years AS (
    SELECT DISTINCT
           mc."PID"                AS actor_id,
           CAST(m."year" AS INT)   AS yr
    FROM "M_Cast"  mc
    JOIN "Movie"   m
         ON mc."MID" = m."MID"
    WHERE m."year" GLOB '[0-9]*'          -- keep rows whose year is numeric
),
year_gaps AS (
    SELECT
           actor_id,
           yr,
           LEAD(yr) OVER (PARTITION BY actor_id ORDER BY yr) AS next_yr
    FROM actor_years
),
actors_with_big_gap AS (                      -- gap of 4‑plus missing years ⇒ diff ≥ 5
    SELECT DISTINCT actor_id
    FROM year_gaps
    WHERE next_yr IS NOT NULL
      AND next_yr - yr >= 5
),
valid_actors AS (
    SELECT DISTINCT actor_id
    FROM actor_years
    WHERE actor_id NOT IN (SELECT actor_id FROM actors_with_big_gap)
)
SELECT COUNT(*) AS num_actors_without_4_year_gap
FROM valid_actors;