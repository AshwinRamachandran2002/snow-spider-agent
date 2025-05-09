/*  How many actors have appeared in more films with Yash Chopra
    than with any other director?  */

WITH yash_director AS (          -- PID of Yash Chopra
    SELECT "PID" AS yash_pid
    FROM   DB_IMDB.DB_IMDB.PERSON
    WHERE  UPPER(TRIM("Name")) = 'YASH CHOPRA'
    LIMIT  1
),

/*  Actor-director collaboration counts (distinct films).
    One row per actor-director pair with number of shared movies. */
actor_director_counts AS (
    SELECT
        mc."PID"              AS actor_pid,
        md."PID"              AS director_pid,
        COUNT(DISTINCT mc."MID") AS movie_count
    FROM   DB_IMDB.DB_IMDB.M_CAST     mc
    JOIN   DB_IMDB.DB_IMDB.M_DIRECTOR md
           ON mc."MID" = md."MID"
    GROUP  BY actor_pid, director_pid
),

/*  Number of films each actor made with Yash Chopra. */
actor_yash_counts AS (
    SELECT
        adc.actor_pid,
        adc.movie_count        AS yash_movie_count
    FROM   actor_director_counts adc
    JOIN   yash_director       yd
           ON adc.director_pid = yd.yash_pid
),

/*  Highest film count each actor has with any OTHER director. */
actor_other_max AS (
    SELECT
        adc.actor_pid,
        MAX(adc.movie_count)   AS other_max_count
    FROM   actor_director_counts adc
    JOIN   yash_director       yd
           ON adc.director_pid <> yd.yash_pid
    GROUP  BY adc.actor_pid
),

/*  Actors whose Yash-Chopra count exceeds every other director count. */
actors_more_with_yash AS (
    SELECT ayc.actor_pid
    FROM   actor_yash_counts ayc
    LEFT   JOIN actor_other_max aom
           ON ayc.actor_pid = aom.actor_pid
    WHERE  ayc.yash_movie_count > COALESCE(aom.other_max_count, 0)
)

SELECT COUNT(DISTINCT actor_pid) AS actors_preferring_yash_chopra
FROM   actors_more_with_yash;