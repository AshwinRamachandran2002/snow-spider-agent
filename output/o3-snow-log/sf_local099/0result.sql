/*  How many actors have appeared in more films with director Yash Chopra
    than with any other director?  */

WITH
/* 1.  Actor–director collaboration counts (one row per actor-director pair) */
collab AS (
    SELECT
        c."PID" AS actor_pid,          -- actor
        d."PID" AS director_pid,       -- director
        COUNT(DISTINCT c."MID") AS film_count
    FROM  DB_IMDB.DB_IMDB."M_CAST"     c
    JOIN  DB_IMDB.DB_IMDB."M_DIRECTOR" d
          ON c."MID" = d."MID"
    GROUP BY
        c."PID",
        d."PID"
),

/* 2.  For every actor, the maximum number of films made with any single director */
actor_max AS (
    SELECT
        actor_pid,
        MAX(film_count) AS max_film_count
    FROM collab
    GROUP BY actor_pid
),

/* 3.  Collaboration counts specifically with Yash Chopra */
yash_collab AS (
    SELECT
        col.actor_pid,
        col.film_count           AS yash_film_count,
        am.max_film_count
    FROM  collab                 col
    JOIN  DB_IMDB.DB_IMDB."PERSON" p
          ON col.director_pid = p."PID"
         AND TRIM(p."Name") ILIKE 'Yash Chopra%'      -- Yash Chopra’s row(s)
    JOIN  actor_max              am
          ON am.actor_pid = col.actor_pid
),

/* 4.  How many (if any) different directors tie for an actor’s maximum count */
tie_check AS (
    SELECT
        c.actor_pid,
        COUNT(*) AS directors_with_max
    FROM  collab      c
    JOIN  actor_max   a
          ON a.actor_pid = c.actor_pid
         AND c.film_count = a.max_film_count
    GROUP BY c.actor_pid
)

/* 5.  Final answer: actors whose unique top collaborator is Yash Chopra */
SELECT COUNT(*) AS num_actors
FROM   yash_collab        y
JOIN   tie_check          t  ON t.actor_pid = y.actor_pid
WHERE  y.yash_film_count = y.max_film_count   -- Yash hits the max
  AND  t.directors_with_max = 1;              -- no tie with others