/* How many actors have appeared in more films with director Yash Chopra
   than with any other single director? */
WITH yash AS (
    /* all distinct person-ids for the name “Yash Chopra” */
    SELECT DISTINCT "PID" AS yash_pid
    FROM DB_IMDB.DB_IMDB."PERSON"
    WHERE TRIM("Name") = 'Yash Chopra'
),
actor_director_counts AS (
    /* number of distinct films each actor has done with every director */
    SELECT
        c."PID"                             AS actor_pid,
        d."PID"                             AS director_pid,
        COUNT(DISTINCT c."MID")             AS film_count
    FROM DB_IMDB.DB_IMDB."M_CAST"     c
    JOIN DB_IMDB.DB_IMDB."M_DIRECTOR" d
      ON c."MID" = d."MID"
    GROUP BY
        c."PID",
        d."PID"
),
yash_actor_counts AS (
    /* films each actor has done with Yash Chopra */
    SELECT
        adc.actor_pid,
        adc.film_count                      AS yash_count
    FROM actor_director_counts adc
    JOIN yash
      ON adc.director_pid = yash.yash_pid
),
other_actor_max AS (
    /* max films an actor has done with any OTHER director */
    SELECT
        adc.actor_pid,
        MAX(adc.film_count)                 AS max_other_count
    FROM actor_director_counts adc
    WHERE adc.director_pid NOT IN (SELECT yash_pid FROM yash)
    GROUP BY adc.actor_pid
)
/* final result */
SELECT COUNT(*) AS "num_actors"
FROM yash_actor_counts   yac
LEFT JOIN other_actor_max oam
       ON yac.actor_pid = oam.actor_pid
WHERE yac.yash_count > COALESCE(oam.max_other_count, 0);