/* 1) Get the PID(s) of director Yash Chopra */
WITH yash_chopra_pid AS (
    SELECT DISTINCT d."PID"
    FROM DB_IMDB.DB_IMDB.M_DIRECTOR   d
    JOIN DB_IMDB.DB_IMDB.PERSON       p
          ON p."PID" = d."PID"
    WHERE TRIM(p."Name") ILIKE 'Yash Chopra'        -- match “Yash Chopra”
),

/* 2) Count how many movies every actor has made with every director */
collaborations AS (
    SELECT
        c."PID"      AS actor_pid,
        d."PID"      AS director_pid,
        COUNT(DISTINCT c."MID") AS film_cnt          -- # joint films
    FROM DB_IMDB.DB_IMDB.M_CAST     c
    JOIN DB_IMDB.DB_IMDB.M_DIRECTOR d
          ON c."MID" = d."MID"
    GROUP BY c."PID", d."PID"
),

/* 3) For each actor, capture:
      a) films with Yash Chopra
      b) greatest film-count with any *other* director            */
actor_stats AS (
    SELECT
        actor_pid,
        MAX(CASE WHEN director_pid IN (SELECT * FROM yash_chopra_pid)
                 THEN film_cnt ELSE 0 END)                     AS yash_cnt,
        MAX(CASE WHEN director_pid NOT IN (SELECT * FROM yash_chopra_pid)
                 THEN film_cnt ELSE 0 END)                     AS max_other_cnt
    FROM collaborations
    GROUP BY actor_pid
),

/* 4) Actors whose Yash-Chopra tally exceeds that with every other director */
actors_preferring_yash AS (
    SELECT actor_pid
    FROM actor_stats
    WHERE yash_cnt > max_other_cnt
)

/* 5) Final answer: how many such actors? */
SELECT COUNT(*) AS "NUM_ACTORS"
FROM actors_preferring_yash;