WITH yash AS (
    SELECT PID AS yash_pid
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
    LIMIT 1
),
collab AS (
    /* films an actor shot with every director (actor‑director pair) */
    SELECT 
        mc.PID  AS actor_pid,
        md.PID  AS director_pid,
        COUNT(DISTINCT mc.MID) AS film_cnt
    FROM M_Cast mc
    JOIN M_Director md ON mc.MID = md.MID
    GROUP BY mc.PID, md.PID
),
actor_stats AS (
    /* for each actor: films with Yash vs. max films with any other director */
    SELECT
        c.actor_pid,
        SUM(CASE WHEN c.director_pid = y.yash_pid THEN c.film_cnt END)                     AS yash_films,
        MAX(CASE WHEN c.director_pid <> y.yash_pid THEN c.film_cnt END)                    AS max_other_films
    FROM collab c
    CROSS JOIN yash y
    GROUP BY c.actor_pid
)
/* count actors whose Yash‑Chopra tally strictly exceeds their best with anyone else */
SELECT COUNT(*) AS actors_preferring_yash
FROM actor_stats
WHERE yash_films IS NOT NULL
  AND (max_other_films IS NULL OR yash_films > max_other_films);