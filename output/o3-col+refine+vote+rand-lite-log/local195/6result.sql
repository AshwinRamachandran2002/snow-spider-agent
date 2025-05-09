WITH top_actors AS (
    SELECT fa.actor_id
    FROM film_actor AS fa
    JOIN inventory  AS i ON fa.film_id   = i.film_id
    JOIN rental     AS r ON i.inventory_id = r.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(*) DESC
    LIMIT 5
),
customers_top AS (
    SELECT DISTINCT r.customer_id
    FROM rental    AS r
    JOIN inventory AS i  ON r.inventory_id = i.inventory_id
    JOIN film_actor AS fa ON i.film_id      = fa.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top_actors)
)
SELECT ROUND(
           (SELECT COUNT(*) FROM customers_top) * 100.0 /
           (SELECT COUNT(*) FROM customer)
       , 4) AS percent_customers_top_actors;