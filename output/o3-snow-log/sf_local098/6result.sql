/*  How many actors never experience a span of 4 or more consecutive
    calendar years without appearing in at least one movie?            */

WITH years_per_actor AS (          -- all distinct (actor, numeric year) pairs
    SELECT
        TRIM(c."PID")                    AS "PID",
        TRY_TO_NUMBER(m."year")          AS "yr"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST"  c
    JOIN   "DB_IMDB"."DB_IMDB"."MOVIE"   m
           ON c."MID" = m."MID"
    WHERE  TRY_TO_NUMBER(m."year") IS NOT NULL
    GROUP  BY TRIM(c."PID"), TRY_TO_NUMBER(m."year")
),

gaps AS (                          -- gap = distance to next later credit
    SELECT
        a."PID",
        MIN(b."yr") - a."yr"       AS "gap_years"
    FROM   years_per_actor a
    LEFT   JOIN years_per_actor b
           ON  a."PID" = b."PID"
           AND b."yr" > a."yr"
    GROUP  BY a."PID", a."yr"
),

actors_with_big_gap AS (           -- any gap ≥ 4 disqualifies the actor
    SELECT DISTINCT "PID"
    FROM   gaps
    WHERE  "gap_years" >= 4
)

SELECT COUNT(DISTINCT y."PID") AS "actors_without_4year_gap"
FROM   years_per_actor y
LEFT   JOIN actors_with_big_gap g
       ON y."PID" = g."PID"
WHERE  g."PID" IS NULL;