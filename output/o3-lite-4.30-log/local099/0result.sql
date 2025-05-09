WITH yash_director AS (
    SELECT DISTINCT TRIM(d."PID") AS director_pid
    FROM "M_Director" d
    JOIN "Person" p
      ON TRIM(p."PID") = TRIM(d."PID")
    WHERE TRIM(p."Name") = 'Yash Chopra'
),
yash_films AS (
    SELECT TRIM(c."PID") AS actor_pid,
           COUNT(*)      AS yash_cnt
    FROM "M_Director" d
    JOIN yash_director y
      ON TRIM(d."PID") = y.director_pid
    JOIN "M_Cast" c
      ON c."MID" = d."MID"
    GROUP BY TRIM(c."PID")
),
other_pairs AS (
    SELECT TRIM(c."PID") AS actor_pid,
           TRIM(d."PID") AS director_pid,
           COUNT(*)      AS film_cnt
    FROM "M_Director" d
    JOIN "M_Cast" c
      ON c."MID" = d."MID"
    WHERE TRIM(d."PID") NOT IN (SELECT director_pid FROM yash_director)
    GROUP BY TRIM(c."PID"), TRIM(d."PID")
),
other_max AS (
    SELECT actor_pid,
           MAX(film_cnt) AS max_other
    FROM other_pairs
    GROUP BY actor_pid
),
prefer_yash AS (
    SELECT y.actor_pid
    FROM yash_films y
    LEFT JOIN other_max o USING (actor_pid)
    WHERE y.yash_cnt > COALESCE(o.max_other, 0)
)
SELECT COUNT(*) AS actors_count
FROM prefer_yash;