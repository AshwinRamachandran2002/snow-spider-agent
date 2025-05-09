/*  How many actors never experience a span of 4 or more consecutive years
    (i.e., a gap > 3 years) without at least one movie appearance?          */

WITH actor_years AS (          -- 1. one row per actor-year with valid 4-digit year
    SELECT DISTINCT
           TRIM(mc."PID")                                    AS "PID",
           TRY_TO_NUMBER(REGEXP_SUBSTR(mv."year", '\\d{4}')) AS "year_num"
    FROM DB_IMDB.DB_IMDB."M_CAST"  mc
    JOIN DB_IMDB.DB_IMDB."MOVIE"   mv
      ON mc."MID" = mv."MID"
    WHERE TRY_TO_NUMBER(REGEXP_SUBSTR(mv."year", '\\d{4}')) IS NOT NULL
),
gaps AS (                      -- 2. gap between consecutive active years
    SELECT
        ay."PID",
        ay."year_num",
        LAG(ay."year_num") OVER (PARTITION BY ay."PID"
                                 ORDER BY ay."year_num") AS "prev_year"
    FROM actor_years ay
),
actors_with_large_gap AS (     -- 3. actors who ever have a gap ≥ 4 years
    SELECT DISTINCT "PID"
    FROM gaps
    WHERE "prev_year" IS NOT NULL
      AND ("year_num" - "prev_year") >= 4
)

SELECT COUNT(DISTINCT ay."PID") AS "actors_no_4year_gap"
FROM actor_years ay
WHERE NOT EXISTS (              -- 4. keep only actors WITHOUT such a gap
    SELECT 1
    FROM actors_with_large_gap ag
    WHERE ag."PID" = ay."PID"
);