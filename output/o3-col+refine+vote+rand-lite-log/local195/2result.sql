WITH actor_rental_counts AS (
    SELECT fa.actor_id,
           COUNT(*) AS rental_count
    FROM film_actor AS fa
    JOIN inventory  AS i ON i.film_id      = fa.film_id
    JOIN rental     AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
),
top5_actors AS (
    SELECT actor_id
    FROM actor_rental_counts
    ORDER BY rental_count DESC
    LIMIT 5
),
customers_top5 AS (
    SELECT DISTINCT r.customer_id
    FROM rental     AS r
    JOIN inventory  AS i  ON i.inventory_id = r.inventory_id
    JOIN film_actor AS fa ON fa.film_id     = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top5_actors)
)
SELECT ROUND(
       100.0 * (SELECT COUNT(*) FROM customers_top5) /
               (SELECT COUNT(*) FROM customer), 
       4
) AS percentage_customers_top5;