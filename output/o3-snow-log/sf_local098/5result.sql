WITH actor_years AS (   -- every (actor, year) pair
    SELECT DISTINCT
           TRIM(mc."PID")                                   AS "PID",
           TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '\\d{4}')) AS "yr"
    FROM "DB_IMDB"."DB_IMDB"."M_CAST"  mc
    JOIN "DB_IMDB"."DB_IMDB"."MOVIE"   m  ON mc."MID" = m."MID"
    WHERE TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '\\d{4}')) IS NOT NULL
),
gaps AS (                -- year-to-next-year differences for each actor
    SELECT
           ay."PID",
           ay."yr",
           LEAD(ay."yr") OVER (PARTITION BY ay."PID" ORDER BY ay."yr") AS "next_yr"
    FROM actor_years ay
),
actors_with_4yr_gap AS ( -- actors who have any ≥4-year gap
    SELECT DISTINCT "PID"
    FROM gaps
    WHERE "next_yr" IS NOT NULL
      AND ("next_yr" - "yr") >= 4
),
all_actors AS (          -- every actor appearing in M_CAST
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM "DB_IMDB"."DB_IMDB"."M_CAST"
)
SELECT COUNT(*) AS "actors_without_4yr_gap"
FROM   all_actors
WHERE  "PID" NOT IN (SELECT "PID" FROM actors_with_4yr_gap);