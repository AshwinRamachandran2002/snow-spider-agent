WITH ActorYears AS (
    SELECT TRIM(mc."PID") AS "PID",
           TRY_TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', '')) AS "year_numeric"
    FROM "DB_IMDB"."DB_IMDB"."M_CAST" AS mc
    JOIN "DB_IMDB"."DB_IMDB"."MOVIE" AS m
      ON TRIM(mc."MID") = TRIM(m."MID")
    WHERE TRY_TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', '')) IS NOT NULL
    GROUP BY TRIM(mc."PID"), TRY_TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', ''))
),
ActorGaps AS (
    SELECT
        "PID",
        "year_numeric",
        "year_numeric" - LAG("year_numeric") OVER (PARTITION BY "PID" ORDER BY "year_numeric") AS "gap"
    FROM ActorYears
),
ActorMaxGaps AS (
    SELECT
        "PID",
        MAX("gap") AS "max_gap"
    FROM ActorGaps
    GROUP BY "PID"
)
SELECT COUNT(*) AS "Number_of_actors_without_long_breaks"
FROM ActorMaxGaps
WHERE "max_gap" <= 3 OR "max_gap" IS NULL;