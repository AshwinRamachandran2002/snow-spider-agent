WITH srk AS (                                               -- Shah Rukh Khan’s PID
    SELECT "PID"
    FROM "Person"
    WHERE LOWER(TRIM("Name")) LIKE '%shah%rukh%khan%'
),
srk_movies AS (                                             -- movies that feature SRK
    SELECT DISTINCT "MID"
    FROM "M_Cast"
    WHERE TRIM("PID") IN (SELECT "PID" FROM srk)
),
srk_costars AS (                                            -- all actors who acted with SRK
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM "M_Cast"
    WHERE "MID" IN (SELECT "MID" FROM srk_movies)
      AND TRIM("PID") NOT IN (SELECT "PID" FROM srk)
),
degree2 AS (                                                -- actors with Shahrukh‑number 2
    SELECT DISTINCT TRIM(mc2."PID") AS "PID"
    FROM "M_Cast" mc1
    JOIN "M_Cast" mc2 ON mc1."MID" = mc2."MID"
    WHERE TRIM(mc1."PID") IN (SELECT "PID" FROM srk_costars)      -- acted with an SRK co‑star
      AND mc1."MID" NOT IN (SELECT "MID" FROM srk_movies)         -- in a movie without SRK
      AND TRIM(mc2."PID") NOT IN (SELECT "PID" FROM srk_costars)  -- not a direct SRK co‑star
      AND TRIM(mc2."PID") NOT IN (SELECT "PID" FROM srk)          -- not SRK himself
)
SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM degree2;