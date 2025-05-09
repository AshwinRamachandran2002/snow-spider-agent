WITH "YASH" AS (   -- find Yash Chopra’s PID
    SELECT "PID" AS "YASH_PID"
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE TRIM(LOWER("Name")) = 'yash chopra'
    LIMIT 1
),

"YASH_MOVIES" AS (   -- movies directed by Yash Chopra
    SELECT MD."MID"
    FROM DB_IMDB.DB_IMDB.M_DIRECTOR MD
    JOIN "YASH" y ON MD."PID" = y."YASH_PID"
),

"ACTOR_YASH_COUNTS" AS (  -- how many times each actor appeared in Yash Chopra films
    SELECT MC."PID"   AS "ACTOR_PID",
           COUNT(DISTINCT MC."MID") AS "YASH_COUNT"
    FROM DB_IMDB.DB_IMDB.M_CAST MC
    JOIN "YASH_MOVIES" YM ON MC."MID" = YM."MID"
    GROUP BY MC."PID"
),

"ACTOR_DIRECTOR_COUNTS" AS (  -- actor-to-director film counts for all directors
    SELECT MC."PID" AS "ACTOR_PID",
           MD."PID" AS "DIRECTOR_PID",
           COUNT(DISTINCT MC."MID") AS "FILM_COUNT"
    FROM DB_IMDB.DB_IMDB.M_CAST     MC
    JOIN DB_IMDB.DB_IMDB.M_DIRECTOR MD
      ON MC."MID" = MD."MID"
    GROUP BY MC."PID", MD."PID"
),

"MAX_OTHER_COUNTS" AS (  -- actor’s maximum film count with any director other than Yash Chopra
    SELECT ADC."ACTOR_PID",
           MAX(
               CASE
                   WHEN ADC."DIRECTOR_PID" <> y."YASH_PID" THEN ADC."FILM_COUNT"
               END
           ) AS "MAX_OTHER_COUNT"
    FROM "ACTOR_DIRECTOR_COUNTS" ADC
    CROSS JOIN "YASH" y
    GROUP BY ADC."ACTOR_PID"
)

SELECT COUNT(*) AS "NUM_ACTORS"
FROM "ACTOR_YASH_COUNTS" AYC
JOIN "MAX_OTHER_COUNTS" MOC
  ON AYC."ACTOR_PID" = MOC."ACTOR_PID"
WHERE AYC."YASH_COUNT" > COALESCE(MOC."MAX_OTHER_COUNT", 0);