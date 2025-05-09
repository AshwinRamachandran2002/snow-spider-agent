WITH actor_director_collaborations AS (
    SELECT mc."PID" AS "actor_PID", md."PID" AS "director_PID", COUNT(*) AS "num_films"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN DB_IMDB.DB_IMDB."M_DIRECTOR" md ON mc."MID" = md."MID"
    GROUP BY mc."PID", md."PID"
),
actor_max_collaborations AS (
    SELECT adc."actor_PID", MAX(adc."num_films") AS "max_num_films"
    FROM actor_director_collaborations adc
    GROUP BY adc."actor_PID"
),
actor_top_directors AS (
    SELECT adc."actor_PID", adc."director_PID", adc."num_films"
    FROM actor_director_collaborations adc
    JOIN actor_max_collaborations amc
    ON adc."actor_PID" = amc."actor_PID" AND adc."num_films" = amc."max_num_films"
),
actor_top_directors_count AS (
    SELECT atd."actor_PID", COUNT(*) AS "director_count"
    FROM actor_top_directors atd
    GROUP BY atd."actor_PID"
),
unique_top_actor_director AS (
    SELECT atd."actor_PID", atd."director_PID"
    FROM actor_top_directors atd
    JOIN actor_top_directors_count atdcount ON atd."actor_PID" = atdcount."actor_PID"
    WHERE atdcount."director_count" = 1
)
SELECT COUNT(DISTINCT utad."actor_PID") AS "number_of_actors"
FROM unique_top_actor_director utad
WHERE utad."director_PID" = 'nm0007181';