WITH yash AS (
    SELECT PID AS yash_pid
    FROM Person
    WHERE lower(trim(Name)) = 'yash chopra'
    LIMIT 1
),
actor_director_cnt AS (
    /* how many films every actor has done with every director */
    SELECT mc.PID  AS actor_pid,
           md.PID  AS director_pid,
           COUNT(DISTINCT mc.MID) AS films_together
    FROM M_Cast      mc
    JOIN M_Director  md ON mc.MID = md.MID
    GROUP BY mc.PID, md.PID
),
comparison AS (
    /* compare each actor’s Yash‑Chopra count with his/her best other‑director count */
    SELECT adc.actor_pid,
           SUM(CASE WHEN adc.director_pid = y.yash_pid THEN adc.films_together ELSE 0 END)             AS yash_cnt,
           MAX(CASE WHEN adc.director_pid <> y.yash_pid THEN adc.films_together END)                   AS max_other
    FROM actor_director_cnt adc
    CROSS JOIN yash y
    GROUP BY adc.actor_pid
)
SELECT COUNT(*) AS actors_more_with_yash
FROM comparison
WHERE yash_cnt > COALESCE(max_other,0);