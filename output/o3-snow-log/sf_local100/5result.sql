WITH srk_pid AS (                               -- Shah Rukh Khan’s PID(s)
    SELECT TRIM(p."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.PERSON p
    WHERE LOWER(TRIM(p."Name")) LIKE '%rukh%khan%'
),

first_deg AS (                                  -- Actors who acted with SRK
    SELECT DISTINCT TRIM(c2."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST c1
    JOIN DB_IMDB.DB_IMDB.M_CAST c2
          ON c1."MID" = c2."MID"
    WHERE TRIM(c1."PID") IN (SELECT "PID" FROM srk_pid)
      AND TRIM(c2."PID") NOT IN (SELECT "PID" FROM srk_pid)
),

second_deg_raw AS (                             -- Actors who acted with a first-degree actor
    SELECT DISTINCT TRIM(mc2."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc1
    JOIN DB_IMDB.DB_IMDB.M_CAST mc2
          ON mc1."MID" = mc2."MID"
    WHERE TRIM(mc1."PID") IN (SELECT "PID" FROM first_deg)
)

SELECT
    COUNT(DISTINCT "PID") AS "Shahrukh_Number_2_Count"
FROM second_deg_raw
WHERE "PID" NOT IN (SELECT "PID" FROM first_deg)   -- exclude first-degree actors
  AND "PID" NOT IN (SELECT "PID" FROM srk_pid);    -- exclude SRK himself