/*  Count actors whose careers never contain a gap of 4 or more consecutive years
    without at least one movie appearance (i.e., every gap ≤ 3 years)           */
WITH actor_years AS (                 -- distinct active years for every actor
    SELECT DISTINCT
           mc."PID",
           TRY_TO_NUMBER(m."year") AS "movie_year"
    FROM DB_IMDB.DB_IMDB.M_CAST  mc
    JOIN DB_IMDB.DB_IMDB.MOVIE   m  ON mc."MID" = m."MID"
    WHERE m."year" IS NOT NULL
),
year_gaps AS (                        -- gap to previous active year per actor
    SELECT
        ay."PID",
        ay."movie_year",
        ay."movie_year"
          - LAG(ay."movie_year") OVER (PARTITION BY ay."PID" ORDER BY ay."movie_year") AS "gap_from_prev"
    FROM actor_years ay
),
continuous_actors AS (                -- keep only actors with NO gap ≥ 4 years
    SELECT "PID"
    FROM year_gaps
    GROUP BY "PID"
    HAVING MAX(CASE WHEN "gap_from_prev" >= 4 THEN 1 ELSE 0 END) = 0
)
SELECT COUNT(*) AS "actors_no_4year_gap"
FROM continuous_actors;