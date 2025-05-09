WITH "YASH_PID" AS (
    /* Fetch Yash Chopra’s person-id */
    SELECT "PID"
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE LOWER(TRIM("Name")) = 'yash chopra'
    LIMIT 1
),
/* Count how many movies each actor has done with every director */
"COLLAB" AS (
    SELECT
        mc."PID"  AS "ACTOR_PID",
        md."PID"  AS "DIRECTOR_PID",
        COUNT(DISTINCT mc."MID") AS "MOVIE_CNT"
    FROM DB_IMDB.DB_IMDB.M_CAST     mc
    JOIN DB_IMDB.DB_IMDB.M_DIRECTOR md
      ON mc."MID" = md."MID"
    GROUP BY
        mc."PID",
        md."PID"
),
/* For every actor: movies with Yash Chopra vs. most with any other director */
"ACTOR_STATS" AS (
    SELECT
        c."ACTOR_PID",
        SUM(CASE WHEN c."DIRECTOR_PID" = y."PID"
                 THEN c."MOVIE_CNT" ELSE 0 END)                    AS "YASH_COUNT",
        MAX(CASE WHEN c."DIRECTOR_PID" <> y."PID"
                 THEN c."MOVIE_CNT" ELSE 0 END)                    AS "OTHER_MAX"
    FROM "COLLAB" c
    CROSS JOIN "YASH_PID" y
    GROUP BY
        c."ACTOR_PID"
)
/* How many actors worked on more films with Yash Chopra than with anyone else? */
SELECT COUNT(*) AS "ACTOR_COUNT"
FROM "ACTOR_STATS"
WHERE "YASH_COUNT" > 0          -- collaborated with Yash Chopra
  AND "YASH_COUNT" > "OTHER_MAX";   -- more than with any other director