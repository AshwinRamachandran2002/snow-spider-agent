WITH top5 AS (
    SELECT fa.actor_id
    FROM film_actor fa
    JOIN inventory i ON i.film_id = fa.film_id
    JOIN rental   r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(*) DESC
    LIMIT 5
),
cust_top5 AS (
    SELECT DISTINCT r.customer_id
    FROM rental r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_actor fa ON fa.film_id = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top5)
)
SELECT ROUND(
           100.0 * (SELECT COUNT(*) FROM cust_top5) 
           / (SELECT COUNT(*) FROM customer)
       , 4) AS percentage_of_customers;