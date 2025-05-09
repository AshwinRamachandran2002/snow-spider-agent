WITH
shahrukh AS (                       -- Shah Rukh Khan’s PID
    SELECT TRIM("PID") AS PID
    FROM   "Person"
    WHERE  TRIM("Name") = 'Shah Rukh Khan'
),
srk_movies AS (                     -- movies featuring Shah Rukh Khan
    SELECT DISTINCT "MID"
    FROM   "M_Cast"
    WHERE  TRIM("PID") IN (SELECT PID FROM shahrukh)
),
level1 AS (                         -- direct co‑actors (distance 1)
    SELECT DISTINCT TRIM("PID") AS PID
    FROM   "M_Cast"
    WHERE  "MID" IN (SELECT "MID" FROM srk_movies)
      AND  TRIM("PID") NOT IN (SELECT PID FROM shahrukh)
),
movies_level1 AS (                  -- movies featuring any distance‑1 actor
    SELECT DISTINCT "MID"
    FROM   "M_Cast"
    WHERE  TRIM("PID") IN (SELECT PID FROM level1)
),
level2 AS (                         -- actors at distance 2
    SELECT DISTINCT TRIM("PID") AS PID
    FROM   "M_Cast"
    WHERE  "MID" IN (SELECT "MID" FROM movies_level1)
      AND  TRIM("PID") NOT IN (SELECT PID FROM level1)      -- not distance 1
      AND  TRIM("PID") NOT IN (SELECT PID FROM shahrukh)    -- not Shah Rukh Khan
)
SELECT COUNT(DISTINCT PID) AS actors_with_shahrukh_number_2
FROM   level2;