-- Task: For each actor, calculate their total gross sales from the films they have starred in, and list them in order of highest to lowest gross sales.
SELECT 
    a."actor_id",
    a."first_name",
    a."last_name",
    SUM(p."amount") AS gross_sales
FROM 
    SQLITE_SAKILA.SQLITE_SAKILA."ACTOR" a
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR" fa ON fa."actor_id" = a."actor_id"
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA."FILM" f ON f."film_id" = fa."film_id"
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY" i ON i."film_id" = f."film_id"
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA."RENTAL" r ON r."inventory_id" = i."inventory_id"
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p ON p."rental_id" = r."rental_id"
GROUP BY 
    a."actor_id", a."first_name", a."last_name"
ORDER BY
    gross_sales DESC;