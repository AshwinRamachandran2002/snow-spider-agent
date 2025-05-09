WITH yash_pid AS (
    SELECT PID AS yash_pid
    FROM Person
    WHERE TRIM(Name) LIKE '%Yash Chopra%'
    LIMIT 1
),
actor_director_counts AS (
    SELECT mc.PID AS actor_pid,
           md.PID AS director_pid,
           COUNT(DISTINCT mc.MID) AS movies_together
    FROM M_Cast mc
    JOIN M_Director md ON mc.MID = md.MID
    GROUP BY mc.PID, md.PID
),
actor_stats AS (
    SELECT adc.actor_pid,
           SUM(CASE WHEN adc.director_pid = y.yash_pid THEN adc.movies_together ELSE 0 END) AS yash_movies,
           COALESCE(MAX(CASE WHEN adc.director_pid <> y.yash_pid THEN adc.movies_together END), 0) AS max_other_movies
    FROM actor_director_counts adc
    CROSS JOIN yash_pid y
    GROUP BY adc.actor_pid
)
SELECT COUNT(*) AS num_actors
FROM actor_stats
WHERE yash_movies > max_other_movies;