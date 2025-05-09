WITH yash_pid AS (                         -- Yash Chopra’s person-id(s)
    SELECT "PID"
    FROM   "Person"
    WHERE  "Name" LIKE '%Yash%Chopra%'
),
yash_movies AS (                           -- movies directed by Yash Chopra
    SELECT DISTINCT "MID"
    FROM   "M_Director"
    WHERE  "PID" IN (SELECT "PID" FROM yash_pid)
),
yash_actor_counts AS (                     -- # of Yash-films for every actor
    SELECT mc."PID"         AS "Actor_PID",
           COUNT(DISTINCT mc."MID") AS "Yash_Films"
    FROM   "M_Cast" AS mc
    WHERE  mc."MID" IN (SELECT "MID" FROM yash_movies)
    GROUP BY mc."PID"
),
other_counts AS (                          -- # of films each actor did with every NON-Yash director
    SELECT mc."PID" AS "Actor_PID",
           md."PID" AS "Director_PID",
           COUNT(DISTINCT mc."MID") AS "Films_Together"
    FROM   "M_Cast"     AS mc
    JOIN   "M_Director" AS md
           ON mc."MID" = md."MID"
    WHERE  md."PID" NOT IN (SELECT "PID" FROM yash_pid)
    GROUP BY mc."PID", md."PID"
),
max_other AS (                             -- actor’s maximum films with a single non-Yash director
    SELECT "Actor_PID",
           MAX("Films_Together") AS "Max_Other_Films"
    FROM   other_counts
    GROUP BY "Actor_PID"
)
SELECT COUNT(*) AS "Num_Actors_With_More_Films_With_Yash_Chopra"
FROM (
    SELECT y."Actor_PID"
    FROM   yash_actor_counts AS y
    LEFT JOIN max_other AS m
           ON y."Actor_PID" = m."Actor_PID"
    WHERE  y."Yash_Films" > IFNULL(m."Max_Other_Films", 0)
) AS better_with_yash;