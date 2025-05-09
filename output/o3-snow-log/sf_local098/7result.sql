/*  Count how many actors never have a gap ≥ 4 years between consecutive movie credits  */
WITH film_years AS (               -- unique (actor , numeric-year) pairs
    SELECT DISTINCT
           TRIM(c."PID")               AS "PID",
           TRY_TO_NUMBER(m."year")     AS "yr"
    FROM   DB_IMDB.DB_IMDB.M_CAST   c
    JOIN   DB_IMDB.DB_IMDB.MOVIE    m  ON m."MID" = c."MID"
    WHERE  TRY_TO_NUMBER(m."year") IS NOT NULL        -- discard non-numeric years
      AND  TRIM(c."PID") IS NOT NULL
      AND  TRIM(c."PID") <> ''                        -- exclude blank PIDs
),
year_gaps AS (                      -- each credited year with the next one
    SELECT
           "PID",
           "yr",
           LEAD("yr") OVER (PARTITION BY "PID" ORDER BY "yr") AS "next_yr"
    FROM film_years
),
actor_max_gap AS (                  -- longest gap per actor
    SELECT
           "PID",
           COALESCE(MAX("next_yr" - "yr" - 1), 0) AS "max_gap"
    FROM year_gaps
    GROUP BY "PID"
)
SELECT
       COUNT(*) AS "actors_no_4_year_gap"
FROM actor_max_gap
WHERE "max_gap" <= 3;