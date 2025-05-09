WITH actor_years AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID",
           CAST(m."year" AS INTEGER) AS "yr"
    FROM "M_Cast" AS mc
    JOIN "Movie"  AS m ON mc."MID" = m."MID"
    WHERE m."year" IS NOT NULL AND m."year" <> ''
),
ordered AS (
    SELECT "PID",
           "yr",
           LAG("yr") OVER (PARTITION BY "PID" ORDER BY "yr") AS "prev_yr"
    FROM actor_years
),
gap_actors AS (
    SELECT DISTINCT "PID"
    FROM ordered
    WHERE "prev_yr" IS NOT NULL
      AND ("yr" - "prev_yr") > 3
),
steady_actors AS (
    SELECT DISTINCT "PID"
    FROM actor_years
    WHERE "PID" NOT IN (SELECT "PID" FROM gap_actors)
)
SELECT COUNT(*) AS actor_count
FROM steady_actors;