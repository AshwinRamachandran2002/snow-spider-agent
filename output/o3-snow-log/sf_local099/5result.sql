/* 1. Find Yash Chopra’s PID            */
WITH yash_pid_cte AS (
    SELECT "PID" AS yash_pid
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE TRIM("Name") = 'Yash Chopra'
    LIMIT 1
),

/* 2. How many films has every actor made with every director? */
actor_director_counts AS (
    SELECT
        c."PID"        AS actor_pid,
        d."PID"        AS director_pid,
        COUNT(*)       AS movie_count
    FROM DB_IMDB.DB_IMDB.M_CAST      c
    JOIN DB_IMDB.DB_IMDB.M_DIRECTOR  d
          ON c."MID" = d."MID"
    GROUP BY
        c."PID",
        d."PID"
),

/* 3. # films each actor made with Yash Chopra                 */
yash_collabs AS (
    SELECT
        a.actor_pid,
        a.movie_count AS yash_count
    FROM actor_director_counts a
    JOIN yash_pid_cte y
          ON a.director_pid = y.yash_pid
),

/* 4. Highest # films same actor made with ANY other director   */
other_collabs AS (
    SELECT
        a.actor_pid,
        MAX(a.movie_count) AS other_max_count
    FROM actor_director_counts a
    JOIN yash_pid_cte y
          ON a.director_pid <> y.yash_pid
    GROUP BY
        a.actor_pid
),

/* 5. Actors whose Yash total > any other-director total        */
qualified_actors AS (
    SELECT
        y.actor_pid
    FROM yash_collabs   y
    LEFT JOIN other_collabs o
           ON y.actor_pid = o.actor_pid
    WHERE y.yash_count > COALESCE(o.other_max_count, 0)
)

/* 6. Final answer                                              */
SELECT COUNT(*) AS "ACTORS_MORE_WITH_YASH"
FROM   qualified_actors;