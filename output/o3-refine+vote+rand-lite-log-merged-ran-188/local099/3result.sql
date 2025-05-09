WITH
-- Yash Chopra’s person‑id
ypid AS (
    SELECT "PID"
    FROM "Person"
    WHERE TRIM("Name") = 'Yash Chopra'
    LIMIT 1
),

-- number of movies every actor has done with every director
collab AS (
    SELECT
        mc."PID"  AS actor_pid,
        md."PID"  AS director_pid,
        COUNT(DISTINCT mc."MID") AS cnt
    FROM "M_Cast"     mc
    JOIN "M_Director" md ON mc."MID" = md."MID"
    GROUP BY mc."PID", md."PID"
),

-- how many movies each actor has made with Yash Chopra
yash_cnt AS (
    SELECT actor_pid, cnt AS yash_cnt
    FROM collab
    WHERE director_pid = (SELECT "PID" FROM ypid)
),

-- their maximum movie count with any *other* director
other_max AS (
    SELECT actor_pid, MAX(cnt) AS other_cnt
    FROM collab
    WHERE director_pid <> (SELECT "PID" FROM ypid)
    GROUP BY actor_pid
),

-- actors whose Yash Chopra count is strictly greater than with any other director
qualified AS (
    SELECT y.actor_pid
    FROM yash_cnt y
    LEFT JOIN other_max o ON y.actor_pid = o.actor_pid
    WHERE y.yash_cnt > COALESCE(o.other_cnt, 0)
)

SELECT COUNT(*) AS num_actors
FROM qualified;