WITH "YASH" AS (  -- Yash Chopra’s PID
    SELECT MIN("PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE UPPER(TRIM("Name")) LIKE '%YASH CHOPRA%'
),

"YASH_MOVIES" AS (  -- movies directed by Yash Chopra
    SELECT DISTINCT d."MID"
    FROM DB_IMDB.DB_IMDB.M_DIRECTOR d
    JOIN "YASH" y
      ON d."PID" = y."PID"
),

"ACTOR_YASH" AS (   -- Yash Chopra film count per actor
    SELECT c."PID" AS actor_pid,
           COUNT(DISTINCT c."MID") AS yash_count
    FROM DB_IMDB.DB_IMDB.M_CAST c
    WHERE c."MID" IN (SELECT "MID" FROM "YASH_MOVIES")
    GROUP BY c."PID"
),

"ACTOR_OTHER_MAX" AS (   -- max film count with any other director per actor
    SELECT sub.actor_pid,
           MAX(sub.movie_cnt) AS max_other_count
    FROM (
        SELECT c."PID" AS actor_pid,
               d."PID"       AS other_dir_pid,
               COUNT(DISTINCT c."MID") AS movie_cnt
        FROM DB_IMDB.DB_IMDB.M_CAST     c
        JOIN DB_IMDB.DB_IMDB.M_DIRECTOR d
          ON c."MID" = d."MID"
        JOIN "YASH" y ON 1=1
        WHERE d."PID" <> y."PID"        -- exclude Yash Chopra
        GROUP BY c."PID", d."PID"
    ) sub
    GROUP BY sub.actor_pid
),

"ACTORS_PREFERRING_YASH" AS (  -- actors who worked more with Yash Chopra
    SELECT a.actor_pid
    FROM "ACTOR_YASH"  a
    LEFT JOIN "ACTOR_OTHER_MAX" o
           ON a.actor_pid = o.actor_pid
    WHERE a.yash_count > COALESCE(o.max_other_count, 0)
)

SELECT COUNT(*) AS "NUM_ACTORS"
FROM "ACTORS_PREFERRING_YASH";