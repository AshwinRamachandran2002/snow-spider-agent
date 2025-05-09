WITH yash AS (
    SELECT PID
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
    LIMIT 1
),
collaborations AS (
    /* how many films every actor has done with every director */
    SELECT
        c.PID  AS actor_pid,
        d.PID  AS director_pid,
        COUNT(DISTINCT c.MID) AS film_cnt
    FROM M_Cast     AS c
    JOIN M_Director AS d ON c.MID = d.MID
    GROUP BY c.PID, d.PID
),
actor_summary AS (
    /* for each actor: films with Yash, and most with any other director */
    SELECT
        actor_pid,
        SUM(CASE WHEN director_pid = (SELECT PID FROM yash) THEN film_cnt ELSE 0 END)          AS yash_films,
        MAX(CASE WHEN director_pid <> (SELECT PID FROM yash) THEN film_cnt ELSE 0 END)         AS max_other_films
    FROM collaborations
    GROUP BY actor_pid
)
SELECT COUNT(*) AS actors_more_with_yash
FROM actor_summary
WHERE yash_films > 0                      -- worked with Yash at least once
  AND yash_films > COALESCE(max_other_films,0);   -- and more times than with anyone else