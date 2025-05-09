WITH yash_cnt AS (
    -- films each actor has done with Yash Chopra
    SELECT TRIM(c."PID") AS actor_pid,
           COUNT(*)      AS yash_movies
    FROM   "M_Cast"     AS c
    JOIN   "M_Director" AS d ON d."MID" = c."MID"
    WHERE  d."PID" = 'nm0007181'                 -- Yash Chopra’s PID
    GROUP BY TRIM(c."PID")
),
other_max AS (
    -- actor’s best collaboration count with any other director
    SELECT actor_pid,
           MAX(collab_cnt) AS max_other_movies
    FROM (
        SELECT TRIM(c."PID") AS actor_pid,
               d."PID"       AS director_pid,
               COUNT(*)      AS collab_cnt
        FROM   "M_Cast"     AS c
        JOIN   "M_Director" AS d ON d."MID" = c."MID"
        WHERE  d."PID" <> 'nm0007181'            -- exclude Yash Chopra
        GROUP BY TRIM(c."PID"), d."PID"
    )
    GROUP BY actor_pid
)
-- actors whose Yash film‑count exceeds their best with any other director
SELECT COUNT(*) AS actors_preferring_Yash
FROM   yash_cnt  AS y
LEFT   JOIN other_max AS o ON o.actor_pid = y.actor_pid
WHERE  y.yash_movies > COALESCE(o.max_other_movies, 0);