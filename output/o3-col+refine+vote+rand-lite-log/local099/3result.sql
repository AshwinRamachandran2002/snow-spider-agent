WITH actor_yash AS (                -- movies each actor did with Yash Chopra
    SELECT TRIM(c."PID") AS actorPID,
           COUNT(*)      AS yash_count
    FROM   "M_Cast"     c
    JOIN   "M_Director" d ON d."MID" = c."MID"
    WHERE  TRIM(d."PID") = 'nm0007181'          -- Yash Chopra’s PID
    GROUP BY actorPID
),
actor_dir AS (                      -- movies each actor did with every director
    SELECT TRIM(c."PID") AS actorPID,
           TRIM(d."PID") AS directorPID,
           COUNT(*)      AS cnt
    FROM   "M_Cast"     c
    JOIN   "M_Director" d ON d."MID" = c."MID"
    GROUP BY actorPID, directorPID
),
max_other AS (                      -- best (max) collaboration count per actor excluding Yash
    SELECT actorPID,
           MAX(cnt) AS max_cnt_other
    FROM   actor_dir
    WHERE  directorPID <> 'nm0007181'
    GROUP BY actorPID
)
SELECT COUNT(*) AS num_actors       -- actors with more films with Yash than with anyone else
FROM   actor_yash ay
LEFT   JOIN max_other mo ON mo.actorPID = ay.actorPID
WHERE  ay.yash_count > COALESCE(mo.max_cnt_other, 0);