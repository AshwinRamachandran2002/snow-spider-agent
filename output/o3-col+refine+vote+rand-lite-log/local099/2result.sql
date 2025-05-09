WITH yash_pid AS (
    SELECT PID
    FROM Person
    WHERE TRIM(Name) LIKE '%Yash Chopra%'
),
yash_counts AS (                -- films each actor did with Yash Chopra
    SELECT TRIM(c.PID) AS actor_pid,
           COUNT(*)     AS yash_collabs
    FROM   M_Cast     AS c
    JOIN   M_Director AS d ON c.MID = d.MID
    WHERE  d.PID IN (SELECT PID FROM yash_pid)
    GROUP  BY TRIM(c.PID)
),
other_counts AS (               -- films each actor did with every other director
    SELECT TRIM(c.PID) AS actor_pid,
           d.PID       AS director_pid,
           COUNT(*)    AS num_movies
    FROM   M_Cast     AS c
    JOIN   M_Director AS d ON c.MID = d.MID
    WHERE  d.PID NOT IN (SELECT PID FROM yash_pid)
    GROUP  BY TRIM(c.PID), d.PID
),
max_other AS (                  -- actor’s biggest collaboration with a non-Yash director
    SELECT actor_pid,
           MAX(num_movies) AS max_other_collabs
    FROM   other_counts
    GROUP  BY actor_pid
)
SELECT COUNT(*) AS num_actors_more_with_yash
FROM (
    SELECT y.actor_pid
    FROM   yash_counts AS y
    LEFT   JOIN max_other AS mo ON y.actor_pid = mo.actor_pid
    WHERE  y.yash_collabs > COALESCE(mo.max_other_collabs, 0)   -- strictly more with Yash
);