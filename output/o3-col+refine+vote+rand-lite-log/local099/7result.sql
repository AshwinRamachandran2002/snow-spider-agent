WITH yash_counts AS (
    SELECT 
        TRIM(c."PID")      AS actor_pid,
        COUNT(*)           AS yash_films
    FROM "M_Cast"     AS c
    JOIN "M_Director" AS d  ON d."MID" = c."MID"
    JOIN "Person"     AS p  ON p."PID" = d."PID"
    WHERE p."Name" LIKE '%Yash%Chopra%'
    GROUP BY actor_pid
),
other_counts AS (
    SELECT 
        TRIM(c."PID")      AS actor_pid,
        d."PID"            AS director_pid,
        COUNT(*)           AS films_together
    FROM "M_Cast"     AS c
    JOIN "M_Director" AS d ON d."MID" = c."MID"
    GROUP BY actor_pid, director_pid
),
max_other AS (
    SELECT 
        oc.actor_pid,
        MAX(oc.films_together) AS max_with_other
    FROM other_counts AS oc
    JOIN "Person"    AS p ON p."PID" = oc.director_pid
    WHERE p."Name" NOT LIKE '%Yash%Chopra%'
    GROUP BY oc.actor_pid
),
better_with_yash AS (
    SELECT yc.actor_pid
    FROM   yash_counts AS yc
    LEFT   JOIN max_other AS mo ON mo.actor_pid = yc.actor_pid
    WHERE  yc.yash_films > IFNULL(mo.max_with_other, 0)
)
SELECT COUNT(*) AS actors_preferring_yash_chopra
FROM   better_with_yash;