WITH yash AS (                          -- find Yash Chopra’s PID
    SELECT "PID" AS yash_pid
    FROM   "Person"
    WHERE  "Name" LIKE '%Yash%Chopra%'
    LIMIT  1
),
yash_movies AS (                        -- all movies directed by Yash Chopra
    SELECT  "MID"
    FROM    "M_Director", yash
    WHERE   "PID" = yash.yash_pid
),
actor_yash_counts AS (                  -- how many Yash-films each actor appeared in
    SELECT  TRIM(mc."PID")         AS actor_id,
            COUNT(DISTINCT mc."MID") AS yash_collabs
    FROM    "M_Cast" mc
    WHERE   mc."MID" IN (SELECT "MID" FROM yash_movies)
    GROUP BY actor_id
),
actor_other_max AS (                    -- actor’s max collabs with any OTHER director
    SELECT  actor_id,
            MAX(num_movies) AS best_with_other
    FROM   (
            SELECT  TRIM(mc."PID")           AS actor_id,
                    md."PID"                 AS director_id,
                    COUNT(DISTINCT mc."MID") AS num_movies
            FROM    "M_Cast"     mc
            JOIN    "M_Director" md ON md."MID" = mc."MID"
            WHERE   md."PID" <> (SELECT yash_pid FROM yash)
            GROUP BY actor_id, director_id
          )
    GROUP BY actor_id
)
SELECT COUNT(*) AS num_actors_with_more_films_with_yash
FROM   actor_yash_counts AS y
LEFT   JOIN actor_other_max AS o USING (actor_id)
WHERE  y.yash_collabs > COALESCE(o.best_with_other, 0);