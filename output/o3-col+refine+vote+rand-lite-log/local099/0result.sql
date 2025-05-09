WITH yc_counts AS (         -- films each actor did with director Yash Chopra
    SELECT TRIM(c."PID") AS actor_PID,
           COUNT(*)      AS yash_chopra_films
    FROM   "M_Cast"     AS c
    JOIN   "M_Director" AS d
           ON d."MID" = c."MID"
    WHERE  TRIM(d."PID") = 'nm0007181'          -- Yash Chopra’s PID
    GROUP  BY actor_PID
),
other_dir_counts AS (       -- max films the same actor did with any *other* director
    SELECT actor_PID,
           MAX(films_together) AS max_with_other_dir
    FROM (
        SELECT TRIM(c."PID")  AS actor_PID,
               TRIM(d."PID")  AS director_PID,
               COUNT(*)       AS films_together
        FROM   "M_Cast"     AS c
        JOIN   "M_Director" AS d
               ON d."MID" = c."MID"
        WHERE  TRIM(d."PID") <> 'nm0007181'
        GROUP  BY actor_PID, director_PID
    )
    GROUP  BY actor_PID
)
SELECT COUNT(*) AS actors_preferring_Yash_Chopra
FROM   yc_counts   AS yc
LEFT   JOIN other_dir_counts AS od
       ON od.actor_PID = yc.actor_PID
WHERE  yc.yash_chopra_films > COALESCE(od.max_with_other_dir, 0);