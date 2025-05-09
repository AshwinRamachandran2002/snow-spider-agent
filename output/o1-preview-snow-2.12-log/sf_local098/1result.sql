WITH actor_years AS (
    SELECT DISTINCT mc."PID",
           CAST(TRY_TO_NUMBER(TRIM(m."year")) AS INTEGER) AS "year"
    FROM "DB_IMDB"."DB_IMDB"."M_CAST" mc
    JOIN "DB_IMDB"."DB_IMDB"."MOVIE" m ON TRIM(mc."MID") = TRIM(m."MID")
    WHERE TRY_TO_NUMBER(TRIM(m."year")) IS NOT NULL
),
actor_gaps AS (
    SELECT ay."PID",
           ay."year",
           ay."year" - LAG(ay."year") OVER (PARTITION BY ay."PID" ORDER BY ay."year") AS gap
    FROM actor_years ay
),
actors_with_long_gaps AS (
    SELECT DISTINCT ag."PID"
    FROM actor_gaps ag
    WHERE ag.gap > 3
),
actors_without_long_gaps AS (
    SELECT DISTINCT ay."PID"
    FROM actor_years ay
    LEFT JOIN actors_with_long_gaps awlg ON ay."PID" = awlg."PID"
    WHERE awlg."PID" IS NULL
)
SELECT COUNT(*) AS "Number_of_actors_without_long_gap"
FROM actors_without_long_gaps;