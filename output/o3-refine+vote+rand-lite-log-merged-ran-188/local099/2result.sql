WITH yash AS (
    SELECT PID
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
),
actor_dir_counts AS (
    -- how many films every actor has done with every director
    SELECT mc.PID AS actor_pid,
           md.PID AS director_pid,
           COUNT(DISTINCT md.MID) AS films_together
    FROM M_Cast mc
    JOIN M_Director md ON mc.MID = md.MID
    GROUP BY mc.PID, md.PID
),
summary AS (
    -- for each actor: films with Yash Chopra and maximum with any other director
    SELECT adc.actor_pid,
           SUM(CASE WHEN adc.director_pid = y.PID THEN adc.films_together ELSE 0 END)        AS yash_cnt,
           MAX(CASE WHEN adc.director_pid <> y.PID THEN adc.films_together END)              AS max_other_cnt
    FROM actor_dir_counts adc
    CROSS JOIN yash y
    GROUP BY adc.actor_pid
)
SELECT COUNT(*) AS num_actors
FROM summary
WHERE yash_cnt > COALESCE(max_other_cnt, 0);