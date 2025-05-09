WITH actor_rental AS (
    SELECT fa.actor_id,
           COUNT(*) AS rental_cnt
    FROM film_actor fa
    JOIN inventory i   ON i.film_id     = fa.film_id
    JOIN rental   r    ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
),
top_five_actors AS (
    SELECT actor_id
    FROM actor_rental
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_top_actor AS (
    SELECT DISTINCT r.customer_id
    FROM top_five_actors t
    JOIN film_actor fa ON fa.actor_id   = t.actor_id
    JOIN inventory i   ON i.film_id     = fa.film_id
    JOIN rental   r    ON r.inventory_id = i.inventory_id
),
totals AS (
    SELECT 
        (SELECT COUNT(*) FROM customers_top_actor) AS top_actor_customers,
        (SELECT COUNT(*) FROM customer)            AS total_customers
)
SELECT 
    ROUND(top_actor_customers * 100.0 / total_customers, 4) AS percentage_of_customers
FROM totals;