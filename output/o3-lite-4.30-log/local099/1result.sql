SELECT COUNT(*) AS actors_count
FROM (
    /* actors' number of films with Yash Chopra */
    SELECT yc.actor_pid
    FROM (
        SELECT TRIM(c."PID") AS actor_pid,
               COUNT(*)      AS yash_collabs
        FROM   "M_Cast"     c
        JOIN   "M_Director" d ON d."MID" = c."MID"
        WHERE  TRIM(d."PID") = (
               SELECT "PID" FROM "Person"
               WHERE TRIM("Name") = 'Yash Chopra' LIMIT 1)
        GROUP BY actor_pid
    ) AS yc
    /* best collaboration count each actor has with any OTHER director */
    LEFT JOIN (
        SELECT actor_pid,
               MAX(collabs) AS best_with_other
        FROM (
            SELECT TRIM(c."PID") AS actor_pid,
                   TRIM(d."PID") AS director_pid,
                   COUNT(*)      AS collabs
            FROM   "M_Cast"     c
            JOIN   "M_Director" d ON d."MID" = c."MID"
            WHERE  TRIM(d."PID") <> (
                   SELECT "PID" FROM "Person"
                   WHERE TRIM("Name") = 'Yash Chopra' LIMIT 1)
            GROUP BY actor_pid, director_pid
        ) sub
        GROUP BY actor_pid
    ) bo
    ON yc.actor_pid = bo.actor_pid
    /* keep actors whose Yash Chopra count is strictly greater */
    WHERE yc.yash_collabs > COALESCE(bo.best_with_other, 0)
);