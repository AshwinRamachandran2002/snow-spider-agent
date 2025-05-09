WITH yash_counts AS (
    SELECT
        mc."PID" AS actor_pid,
        COUNT(DISTINCT mc."MID") AS yash_movie_count
    FROM
        "DB_IMDB"."DB_IMDB"."M_CAST" mc
    JOIN
        "DB_IMDB"."DB_IMDB"."M_DIRECTOR" md ON mc."MID" = md."MID"
    WHERE
        md."PID" = 'nm0007181'
    GROUP BY
        mc."PID"
),
other_counts AS (
    SELECT
        actor_pid,
        MAX(movie_count) AS max_other_movie_count
    FROM (
        SELECT
            mc."PID" AS actor_pid,
            md."PID" AS director_pid,
            COUNT(DISTINCT mc."MID") AS movie_count
        FROM
            "DB_IMDB"."DB_IMDB"."M_CAST" mc
        JOIN
            "DB_IMDB"."DB_IMDB"."M_DIRECTOR" md ON mc."MID" = md."MID"
        WHERE
            md."PID" != 'nm0007181'
        GROUP BY
            mc."PID",
            md."PID"
    ) AS actor_director_counts
    GROUP BY
        actor_pid
)
SELECT COUNT(*) AS "number_of_actors"
FROM yash_counts yc
LEFT JOIN other_counts oc ON yc.actor_pid = oc.actor_pid
WHERE yc.yash_movie_count > COALESCE(oc.max_other_movie_count, 0);