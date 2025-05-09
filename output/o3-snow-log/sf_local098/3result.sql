WITH actor_years AS (                       -- every distinct (actor, year) pair
    SELECT DISTINCT
           mc."PID",
           TRY_TO_NUMBER(m."year") AS "year"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST"  mc
    JOIN   "DB_IMDB"."DB_IMDB"."MOVIE"   m
           ON mc."MID" = m."MID"
    WHERE  TRY_TO_NUMBER(m."year") IS NOT NULL
), gaps AS (                                -- difference to the next credited year
    SELECT
           ay."PID",
           ay."year",
           LEAD(ay."year") OVER (PARTITION BY ay."PID" ORDER BY ay."year") AS "next_year"
    FROM   actor_years ay
), gap_values AS (                          -- keep only rows that have a following year
    SELECT
           g."PID",
           g."next_year" - g."year" AS "gap"
    FROM   gaps g
    WHERE  g."next_year" IS NOT NULL
), max_gap AS (                             -- largest gap per actor (0 for single-credit actors)
    SELECT
           ay."PID",
           COALESCE(MAX(gv."gap"), 0) AS "max_gap"
    FROM   actor_years ay
    LEFT JOIN gap_values gv
           ON ay."PID" = gv."PID"
    GROUP BY ay."PID"
)
SELECT COUNT(*) AS "actors_no_4yr_gap"
FROM   max_gap
WHERE  "max_gap" <= 3;