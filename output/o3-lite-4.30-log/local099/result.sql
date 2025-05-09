WITH yash_pid AS (
    SELECT TRIM("PID") AS pid
    FROM "Person"
    WHERE TRIM("Name") = 'Yash Chopra'
    LIMIT 1
),
pair_counts AS (
    SELECT TRIM(md."PID") AS director_pid,
           TRIM(mc."PID") AS actor_pid,
           COUNT(*)       AS film_count
    FROM "M_Director" md
    JOIN "M_Cast"     mc ON mc."MID" = md."MID"
    GROUP BY director_pid, actor_pid
),
yash_actor AS (
    SELECT actor_pid,
           film_count AS yash_films
    FROM pair_counts, yash_pid
    WHERE director_pid = yash_pid.pid
),
actor_best_other AS (
    SELECT actor_pid,
           MAX(film_count) AS other_films
    FROM pair_counts, yash_pid
    WHERE director_pid <> yash_pid.pid
    GROUP BY actor_pid
)
SELECT COUNT(*) AS actors_count
FROM yash_actor y
LEFT JOIN actor_best_other o ON o.actor_pid = y.actor_pid
WHERE y.yash_films > COALESCE(o.other_films, 0);