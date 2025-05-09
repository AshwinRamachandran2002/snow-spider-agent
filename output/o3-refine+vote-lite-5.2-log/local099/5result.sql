WITH yash_chopra AS (
    SELECT PID
    FROM Person
    WHERE LOWER(TRIM(Name)) = 'yash chopra'
),
actor_director_counts AS (
    /* how many films each actor made with each director */
    SELECT 
        MC.PID  AS actor_pid,
        MD.PID  AS director_pid,
        COUNT(*) AS films_together
    FROM M_Cast      MC
    JOIN M_Director  MD ON MC.MID = MD.MID
    GROUP BY MC.PID, MD.PID
),
actor_totals AS (
    /* per actor: films with Yash Chopra and the highest count with any other director */
    SELECT
        actor_pid,
        SUM(CASE WHEN director_pid IN (SELECT PID FROM yash_chopra)
                 THEN films_together END)                         AS yash_cnt,
        MAX(CASE WHEN director_pid NOT IN (SELECT PID FROM yash_chopra)
                 THEN films_together END)                         AS max_other_cnt
    FROM actor_director_counts
    GROUP BY actor_pid
)
SELECT COUNT(*) AS actors_preferring_yash_chopra
FROM actor_totals
WHERE yash_cnt IS NOT NULL                -- worked with Yash Chopra
  AND yash_cnt > COALESCE(max_other_cnt,0);   -- more than with any other director