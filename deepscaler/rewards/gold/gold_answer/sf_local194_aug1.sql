-- Task: Please list all films along with the number of actors in each film.
SELECT 
    f."film_id",
    f."title",
    COUNT(fa."actor_id") AS num_actors
FROM 
    SQLITE_SAKILA.SQLITE_SAKILA.FILM f
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa ON fa."film_id" = f."film_id"
GROUP BY 
    f."film_id", f."title"
ORDER BY 
    f."film_id";