SELECT CONCAT(a."first_name", ' ', a."last_name") AS "Actor_Name",
       ROUND((COUNT(DISTINCT r."customer_id") * 100.0) / (SELECT COUNT(DISTINCT "customer_id") FROM SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER), 4) AS "Percentage_of_Customers_Who_Rented_Films_Featuring_Actor"
FROM SQLITE_SAKILA.SQLITE_SAKILA.ACTOR a
JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa ON a."actor_id" = fa."actor_id"
JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY i ON fa."film_id" = i."film_id"
JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL r ON i."inventory_id" = r."inventory_id"
GROUP BY a."actor_id", a."first_name", a."last_name"
ORDER BY COUNT(DISTINCT r."customer_id") DESC NULLS LAST
LIMIT 5;