WITH
-- Shah Rukh Khan’s own PID(s)
srk AS (
    SELECT "PID"
    FROM   "Person"
    WHERE  "Name" LIKE '%Rukh%'        -- matches “…Shah Rukh Khan”
),
-- All movies that actually contain Shah Rukh Khan
srk_movies AS (
    SELECT DISTINCT mc."MID"
    FROM   "M_Cast" mc
    JOIN   srk      ON TRIM(mc."PID") = srk."PID"
),
-- First-degree co-actors (Shah Rukh number = 1)
first_degree AS (
    SELECT DISTINCT TRIM(mc2."PID") AS "PID"
    FROM   "M_Cast" mc1
    JOIN   srk            ON TRIM(mc1."PID") = srk."PID"
    JOIN   "M_Cast" mc2   ON mc1."MID"       = mc2."MID"
    WHERE  TRIM(mc2."PID") <> srk."PID"
),
-- Movies that feature at least one first-degree actor but NOT Shah Rukh Khan
fd_movies_no_srk AS (
    SELECT DISTINCT mc."MID"
    FROM   "M_Cast" mc
    WHERE  TRIM(mc."PID") IN (SELECT "PID" FROM first_degree)
      AND  mc."MID"       NOT IN (SELECT "MID" FROM srk_movies)
),
-- All actors appearing in those movies
potential_second_degree AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM   "M_Cast" mc
    WHERE  mc."MID" IN (SELECT "MID" FROM fd_movies_no_srk)
)
-- Final count: second-degree actors only
SELECT COUNT(*) AS actors_with_ShahRukh_number_2
FROM   (
        SELECT "PID"
        FROM   potential_second_degree
        WHERE  "PID" NOT IN (SELECT "PID" FROM srk)         -- exclude SRK
          AND  "PID" NOT IN (SELECT "PID" FROM first_degree) -- exclude first-degree
       );