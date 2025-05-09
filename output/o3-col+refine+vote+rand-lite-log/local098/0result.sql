WITH actor_years AS (
    -- every (actor, appearance-year) pair
    SELECT DISTINCT
           TRIM(mc."PID")          AS "PID",
           CAST(m."year" AS INT)   AS "yr"
    FROM   "M_Cast"  AS mc
    JOIN   "Movie"   AS m
           ON m."MID" = mc."MID"
    WHERE  m."year" IS NOT NULL
),
year_gaps AS (
    -- previous credit year for each actor
    SELECT  "PID",
            "yr",
            LAG("yr") OVER (PARTITION BY "PID" ORDER BY "yr") AS "prev_yr"
    FROM    actor_years
),
bad_actors AS (
    -- any actor who ever had a gap ≥ 4 years
    SELECT DISTINCT "PID"
    FROM   year_gaps
    WHERE  "prev_yr" IS NOT NULL
       AND ("yr" - "prev_yr") > 3
),
good_actors AS (
    -- actors whose longest gap never exceeded 3 years
    SELECT DISTINCT "PID"
    FROM   actor_years
    WHERE  "PID" NOT IN (SELECT "PID" FROM bad_actors)
)
SELECT COUNT(*) AS "actors_without_4_year_gaps"
FROM   good_actors;