WITH actor_years AS (
    SELECT mc."PID", p."Name", TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', '')) AS "Year"
    FROM "DB_IMDB"."DB_IMDB"."M_CAST" mc
    JOIN "DB_IMDB"."DB_IMDB"."MOVIE" m ON mc."MID" = m."MID"
    JOIN "DB_IMDB"."DB_IMDB"."PERSON" p ON mc."PID" = p."PID"
    WHERE m."year" IS NOT NULL AND REGEXP_REPLACE(m."year", '[^0-9]', '') <> ''
),
actor_gaps AS (
    SELECT
        "PID",
        "Year",
        "Year" - LAG("Year") OVER (PARTITION BY "PID" ORDER BY "Year") AS "Gap"
    FROM actor_years
),
actor_max_gap AS (
    SELECT "PID", MAX("Gap") AS "Max_Gap"
    FROM actor_gaps
    GROUP BY "PID"
)
SELECT COUNT(*) AS "Number_of_actors_without_long_breaks"
FROM actor_max_gap
WHERE COALESCE("Max_Gap", 0) <= 3;