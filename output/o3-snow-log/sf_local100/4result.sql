/*  Count of “Shahrukh-number 2” actors
    – Shahrukh-number 1  = actors who have appeared in any film with Shah Rukh Khan.
    – Shahrukh-number 2  = actors who have appeared with at least one number-1 actor
                           in a film that does NOT feature Shah Rukh Khan himself.
*/
WITH
-- 1) All movie-IDs that contain Shah Rukh Khan
SRK_MOVIES AS (
    SELECT DISTINCT mc."MID"
    FROM   DB_IMDB.DB_IMDB."M_CAST"   mc
    JOIN   DB_IMDB.DB_IMDB."PERSON"   p
           ON TRIM(mc."PID") = TRIM(p."PID")
    WHERE  TRIM(p."Name") ILIKE '%Shah%Khan%'          -- matches “Shah Rukh Khan”
),

-- 2) Shahrukh-number 1 actors (all co-stars from those movies)
SRK1_PIDS AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM   DB_IMDB.DB_IMDB."M_CAST" mc
    WHERE  mc."MID" IN (SELECT "MID" FROM SRK_MOVIES)
),

-- 3) Movies that have at least one number-1 actor but NO Shah Rukh Khan
MOVIES_WITH_SRK1_NO_SRK AS (
    SELECT DISTINCT mc."MID"
    FROM   DB_IMDB.DB_IMDB."M_CAST" mc
    WHERE  TRIM(mc."PID") IN (SELECT "PID" FROM SRK1_PIDS)     -- needs a #1 actor
      AND  mc."MID"       NOT IN (SELECT "MID" FROM SRK_MOVIES) -- exclude SRK movies
),

-- 4) Candidate Shahrukh-number 2 actors (anyone in those movies)
SRK2_CANDIDATES AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM   DB_IMDB.DB_IMDB."M_CAST" mc
    WHERE  mc."MID" IN (SELECT "MID" FROM MOVIES_WITH_SRK1_NO_SRK)
)

-- 5) Final count: candidates minus Shah Rukh Khan himself and all number-1 actors
SELECT COUNT(*) AS "shahrukh_number_2_count"
FROM   SRK2_CANDIDATES c
WHERE  c."PID" NOT IN (SELECT "PID" FROM SRK1_PIDS)           -- remove number-1
  AND  c."PID" NOT IN (                                       -- remove SRK
        SELECT DISTINCT TRIM(p."PID")
        FROM   DB_IMDB.DB_IMDB."PERSON" p
        WHERE  TRIM(p."Name") ILIKE '%Shah%Khan%' );