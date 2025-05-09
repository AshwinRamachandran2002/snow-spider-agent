WITH top5_actors AS (
    SELECT fa.actor_id
    FROM film_actor AS fa
    JOIN inventory  AS i ON i.film_id      = fa.film_id
    JOIN rental     AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 5
),
films_with_top5 AS (
    SELECT DISTINCT fa.film_id
    FROM film_actor AS fa
    WHERE fa.actor_id IN (SELECT actor_id FROM top5_actors)
),
customers_of_top5_films AS (
    SELECT DISTINCT r.customer_id
    FROM rental    AS r
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    WHERE i.film_id IN (SELECT film_id FROM films_with_top5)
),
total_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS cnt
    FROM customer
)
SELECT ROUND(
           100.0 * (SELECT COUNT(*) FROM customers_of_top5_films)
               / (SELECT cnt FROM total_customers),
           4
       ) AS percent_customers_with_top5;