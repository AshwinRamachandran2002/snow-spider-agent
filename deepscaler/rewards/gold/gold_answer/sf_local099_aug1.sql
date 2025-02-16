-- Task: List all actors who have collaborated with Yash Chopra and the number of films they have done together.
SELECT adc."actor_PID", adc."num_films"
FROM (
    SELECT mc."PID" AS "actor_PID", md."PID" AS "director_PID", COUNT(*) AS "num_films"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN DB_IMDB.DB_IMDB."M_DIRECTOR" md ON mc."MID" = md."MID"
    GROUP BY mc."PID", md."PID"
) adc
WHERE adc."director_PID" = 'nm0007181';