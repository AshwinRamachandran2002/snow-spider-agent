WITH yash_director AS (
    SELECT TRIM("PID") AS yash_pid
    FROM   "Person"
    WHERE  TRIM("Name") LIKE '%Yash%Chopra%'
),
yash_collab AS (
    /* films each actor made with Yash Chopra */
    SELECT TRIM(c."PID")        AS actor_pid,
           COUNT(*)             AS yash_count
    FROM   "M_Cast"     c
    JOIN   "M_Director" d ON c."MID" = d."MID"
    WHERE  TRIM(d."PID") IN (SELECT yash_pid FROM yash_director)
    GROUP  BY TRIM(c."PID")
),
other_collab AS (
    /* best collaboration count each actor has with any non-Yash director */
    SELECT actor_pid,
           MAX(collab_cnt)      AS max_other_count
    FROM (
        SELECT TRIM(c."PID")   AS actor_pid,
               TRIM(d."PID")   AS director_pid,
               COUNT(*)        AS collab_cnt
        FROM   "M_Cast"     c
        JOIN   "M_Director" d ON c."MID" = d."MID"
        WHERE  TRIM(d."PID") NOT IN (SELECT yash_pid FROM yash_director)
        GROUP  BY TRIM(c."PID"), TRIM(d."PID")
    )
    GROUP BY actor_pid
)
SELECT COUNT(*) AS actors_preferring_yash
FROM   yash_collab   y
LEFT   JOIN other_collab o ON y.actor_pid = o.actor_pid
WHERE  y.yash_count > COALESCE(o.max_other_count, 0);