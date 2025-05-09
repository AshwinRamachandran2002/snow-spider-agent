WITH yash_pid AS (
  SELECT DISTINCT TRIM("PID") AS pid
  FROM "Person"
  WHERE "Name" LIKE '%Yash%Chopra%'
),
pair_counts AS (
  SELECT TRIM(c."PID") AS actor_pid,
         TRIM(d."PID") AS director_pid,
         COUNT(*)      AS films_together
  FROM "M_Cast"     AS c
  JOIN "M_Director" AS d ON d."MID" = c."MID"
  GROUP BY actor_pid, director_pid
),
max_per_actor AS (
  SELECT actor_pid,
         MAX(films_together) AS max_with_any
  FROM pair_counts
  GROUP BY actor_pid
),
yash_collabs AS (
  SELECT pc.actor_pid,
         pc.films_together AS films_with_yash
  FROM pair_counts AS pc
  JOIN yash_pid    AS y ON pc.director_pid = y.pid
)
SELECT COUNT(*) AS actors_preferring_yash_chopra
FROM   yash_collabs AS y
JOIN   max_per_actor AS m ON m.actor_pid = y.actor_pid
WHERE  y.films_with_yash = m.max_with_any;