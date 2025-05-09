WITH top_actors AS (
    /* 1. Top five actors by total rentals */
    SELECT fa.actor_id,
           COUNT(*) AS rentals
    FROM film_actor fa
    JOIN inventory  i ON i.film_id   = fa.film_id
    JOIN rental     r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY rentals DESC, fa.actor_id
    LIMIT 5
),
customers_with_top_actors AS (
    /* 2. Customers who rented at least one film featuring any of the top actors */
    SELECT DISTINCT r.customer_id
    FROM top_actors ta
    JOIN film_actor fa ON fa.actor_id = ta.actor_id
    JOIN inventory  i  ON i.film_id   = fa.film_id
    JOIN rental     r  ON r.inventory_id = i.inventory_id
)
SELECT ROUND(
         (SELECT COUNT(*) FROM customers_with_top_actors) * 100.0
         / (SELECT COUNT(*) FROM customer), 4
       ) AS percentage_of_customers;