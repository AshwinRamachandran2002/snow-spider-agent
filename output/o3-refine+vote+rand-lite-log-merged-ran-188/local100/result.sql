WITH shah_rukh AS (
    SELECT TRIM("PID") AS pid
    FROM "Person"
    WHERE TRIM("Name") LIKE '%Shah%Rukh%Khan%'
    LIMIT 1
),
direct_coactors AS (
    SELECT DISTINCT TRIM(mc2."PID") AS direct_pid
    FROM "M_Cast" AS mc1
    JOIN "M_Cast" AS mc2
      ON mc1."MID" = mc2."MID"
    WHERE TRIM(mc1."PID") = (SELECT pid FROM shah_rukh)
      AND TRIM(mc2."PID") <> (SELECT pid FROM shah_rukh)
),
second_deg_movies AS (
    SELECT DISTINCT "MID"
    FROM "M_Cast"
    WHERE TRIM("PID") IN (SELECT direct_pid FROM direct_coactors)
),
second_deg_actors AS (
    SELECT DISTINCT TRIM("PID") AS pid
    FROM "M_Cast"
    WHERE "MID" IN (SELECT "MID" FROM second_deg_movies)
      AND TRIM("PID") <> (SELECT pid FROM shah_rukh)
      AND TRIM("PID") NOT IN (SELECT direct_pid FROM direct_coactors)
)
SELECT COUNT(*) AS shahrukh_number_2
FROM second_deg_actors;